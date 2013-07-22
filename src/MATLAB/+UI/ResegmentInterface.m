function ResegmentInterface()
    global Figures CellFamilies CellTracks ResegState bResegPaused
    
    if ( ~isempty(ResegState) )
        return;
    end
    
    defValue = {''};
    if ( Figures.tree.familyID > 0)
        defValue = {num2str(CellFamilies(Figures.tree.familyID).rootTrackID)};
    end
    
    cellStr = inputdlg('Enter root cell IDs','Resegment Cells', 1, defValue);
    if ( isempty(cellStr) )
        return;
    end
    
    checkCells = str2num(cellStr{1});
    if ( isempty(checkCells) )
        warndlg('List incorrectly formatted, please enter cell IDs separated by spaces');
        return;
    end
    
    bResegPaused = 0;
    preserveFam = [CellTracks(checkCells).familyID];
    
    hToolbar = addButtons();
    
    tStart = max(Figures.time, 2);
    bErr = Editor.ReplayableEditAction(@Editor.ResegInitializeAction, preserveFam, tStart);
    if ( bErr )
        delete(hToolbar);
    end
    
    Editor.ReplayableEditAction(@Editor.StartReplayableSubtask, 'InteractiveResegTask');
    
    bFinished = runReseg(hToolbar);
    if ( bFinished )
        cleanupReseg(hToolbar);
    end
end

function bFinished = runReseg(hToolbar)
    global Figures CellHulls HashedCells Costs ResegState bResegPaused
    
    bFinished = false;

    % Need to worry about deleted hulls?
    costMatrix = Costs;
    bDeleted = ([CellHulls.deleted] > 0);
    costMatrix(bDeleted,:) = 0;
    costMatrix(:,bDeleted) = 0;

    mexDijkstra('initGraph', costMatrix);
    
    tStart = ResegState.currentTime;
    tMax = length(HashedCells);
    tEnd = length(HashedCells);
    
    setPlayToolbarState(hToolbar);
    
    for t=tStart:tEnd
        bErr = Editor.ReplayableEditAction(@Editor.ResegFrameAction, t, tMax);
        
        Figures.time = t;
        UI.DrawTree(ResegState.primaryTree);
        UI.DrawCells();
        
        if ( bErr )
            pauseReseg(hToolbar);
            return;
        end
        
        % Do not remove, guarantees UI callbacks from toolbar are
        % processed.
        drawnow();
        
        % For forward frame-step
        if ( t == tEnd )
            break;
        end
        
        if ( isempty(ResegState) || isempty(bResegPaused) )
            return;
        end
        
        if ( bResegPaused )
            return;
        end
    end
    
    Figures.time = tEnd;
    UI.DrawTree(ResegState.primaryTree);
    UI.DrawCells();
    
    bFinished = true;
end

function cleanupReseg(hToolbar)
    [bErr finishTime] = Editor.ReplayableEditAction(@Editor.ResegFinishAction);
    Editor.ReplayableEditAction(@Editor.StopReplayableSubtask, finishTime-1, 'InteractiveResegTask');
    
    delete(hToolbar);
end

function playReseg(hToolbar)
    global ResegState bResegPaused
    
    setProcessingToolbarState(hToolbar);

    % Prepare to start playing resegmentation again, consolidate pause edits
    Editor.ReplayableEditAction(@Editor.StopReplayableSubtask, ResegState.currentTime-1, 'PauseResegTask');
    bErr = Editor.ReplayableEditAction(@Editor.ResegPlayAction);
    bFinished = runReseg(hToolbar);
    if ( bFinished )
        cleanupReseg(hToolbar);
        return;
    end
end

function pauseReseg(hToolbar)
    setProcessingToolbarState(hToolbar);

    % Pause resegmentation, make new subtask for edits while paused
    Editor.ReplayableEditAction(@Editor.StartReplayableSubtask, 'PauseResegTask');
    bErr = Editor.ReplayableEditAction(@Editor.ResegPauseAction);

    setPausedToolbarState(hToolbar);
end

function toggleReseg(src,evnt)
    global ResegState bResegPaused
    if ( isempty(ResegState) )
        return;
    end
    
    hToolbar = get(src, 'Parent');
    if ( bResegPaused )
        playReseg(hToolbar);
    else
        pauseReseg(hToolbar);
    end
end

function backupReseg(src,evnt)
    global Figures ResegState bResegPaused
    if ( isempty(ResegState) || isempty(bResegPaused) )
        return;
    end
    
    if ( ~bResegPaused )
        return;
    end
    
    hToolbar = get(src, 'Parent');
    
    resegLevel = Editor.StackedHistory.GetDepth()-1;
    if ( ~Editor.StackedHistory.CanUndo(resegLevel) )
        setPausedToolbarState(hToolbar);
        return;
    end
    
    Editor.ReplayableEditAction(@Editor.DropReplayableSubtask, 'PauseResegTask');
    Editor.ReplayableEditAction(@Editor.Top);
    
    bErr = Editor.ReplayableEditAction(@Editor.ResegBackAction);
    
    Editor.ReplayableEditAction(@Editor.StartReplayableSubtask, 'PauseResegTask');
    
    setPausedToolbarState(hToolbar);
end

function forwardReseg(src,evnt)
    global Figures HashedCells ResegState bResegPaused
    if ( isempty(ResegState) || isempty(bResegPaused) )
%         delete(get(src,'Parent'));
        return;
    end
    
    if ( ~bResegPaused )
        return;
    end
    
    hToolbar = get(src, 'Parent');
    
    if ( ResegState.currentTime == length(HashedCells) )
        setPausedToolbarState(hToolbar);
        return;
    end
    
    setProcessingToolbarState(hToolbar);
    
    Editor.ReplayableEditAction(@Editor.StopReplayableSubtask, ResegState.currentTime-1, 'PauseResegTask');
    bErr = Editor.ReplayableEditAction(@Editor.ResegForwardAction);
    bFinished = runReseg(hToolbar);
    if ( bFinished )
        cleanupReseg(hToolbar)
        return;
    end
    
    Editor.ReplayableEditAction(@Editor.StartReplayableSubtask, 'PauseResegTask');
    
    setPausedToolbarState(hToolbar);
end

function finishReseg(src,evnt)
    global Figures ResegState bResegPaused
    
    if ( bResegPaused )
        Editor.ReplayableEditAction(@Editor.StopReplayableSubtask, ResegState.currentTime-1, 'PauseResegTask');
    end
    
    hToolbar = get(src,'Parent');
    cleanupReseg(hToolbar)
end

function setPausedToolbarState(hToolbar)
    global ResegState HashedCells
    
    hButtons = get(hToolbar, 'Children');
    
    playIm = imread('+UI\play.png');
    set(hButtons(3),'CData',playIm, 'TooltipString','Continue Resegmentation');
    
    % Set back state
    resegLevel = Editor.StackedHistory.GetDepth()-1;
    if ( ~Editor.StackedHistory.CanUndo(resegLevel) )
        set(hButtons(4), 'Enable','off');
    else
        set(hButtons(4), 'Enable','on');
    end

    % Set forward state
    if ( ResegState.currentTime == length(HashedCells) )
        set(hButtons(2), 'Enable','off');
    else
        set(hButtons(2), 'Enable','on');
    end
    
    set(hButtons(3), 'Enable','on');
    set(hButtons(1), 'Enable','on');
end

function setPlayToolbarState(hToolbar)
    hButtons = get(hToolbar, 'Children');
    
    pauseIm = imread('+UI\pause.png');
    set(hButtons(3),'CData',pauseIm, 'TooltipString','Pause Resegmentation');
    
    set(hButtons(4), 'Enable','off');
    set(hButtons(2), 'Enable','off');
    
    set(hButtons(3), 'Enable','on');
    set(hButtons(1), 'Enable','on');
end

function setProcessingToolbarState(hToolbar)
    hButtons = get(hToolbar, 'Children');
    
    set(hButtons, 'Enable','off');
end

function hToolbar = addButtons()
    global Figures
    
%     set(Figures.cells.handle, 'Toolbar','none');
    
    hToolbar = uitoolbar(Figures.cells.handle);
    backIm = imread('+UI\backFrame.png');
    playIm = imread('+UI\play.png');
    pauseIm = imread('+UI\pause.png');
    forwardIm = imread('+UI\forwardFrame.png');
%     revertIm = imread('+UI\revert.png');
    finishIm = imread('+UI\stop.png');
    
    toolHandles = [];
    
    hpt = uipushtool(hToolbar, 'CData',backIm, 'ClickedCallback',@backupReseg, 'TooltipString','Undo 1 Frame');
    set(hpt, 'Enable','off');
    toolHandles = [toolHandles; hpt];
    
    hpt = uipushtool(hToolbar, 'CData',pauseIm, 'ClickedCallback',@toggleReseg, 'TooltipString','Pause Resegmentation');
    toolHandles = [toolHandles; hpt];
    
    hpt = uipushtool(hToolbar, 'CData',forwardIm, 'ClickedCallback',@forwardReseg, 'TooltipString','Forward 1 Frame');
    set(hpt, 'Enable','off');
    toolHandles = [toolHandles; hpt];
    
%     uipushtool(hToolbar, 'CData',revertIm, 'ClickedCallback',@abortReseg, 'TooltipString','Revert all changes', 'Separator','on');
    hpt = uipushtool(hToolbar, 'CData',finishIm, 'ClickedCallback',@finishReseg, 'TooltipString','Finish', 'Separator','on');
    toolHandles = [toolHandles; hpt];
    
    set(hToolbar, 'UserData',toolHandles);
end
