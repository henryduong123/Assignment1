function ResegmentInterface()
    global Figures CellFamilies CellTracks ResegState bResegPaused bResegTransition
    
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
    
    checkCells = str2num(cellStr{1}); %#ok<ST2NM>
    if ( isempty(checkCells) )
        warndlg('List incorrectly formatted, please enter cell IDs separated by spaces');
        return;
    end
    
    bResegTransition = false;
    bResegPaused = false;
    preserveFam = [CellTracks(checkCells).familyID];
    
    hToolbar = addButtons();
    
    set(Figures.cells.handle, 'BusyAction','queue', 'Interruptible','on');
    set(Figures.tree.handle, 'BusyAction','queue', 'Interruptible','on');
    
    tStart = max(Figures.time, 2);
    xlims = get(Figures.tree.axesHandle,'XLim');
    hold(Figures.tree.axesHandle,'on');
    plot(Figures.tree.axesHandle, [xlims(1), xlims(2)],[tStart, tStart], '-b');
    hold(Figures.tree.axesHandle,'off');
    
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
        xl = xlim(Figures.cells.axesHandle);
        yl = ylim(Figures.cells.axesHandle);
        
        bErr = Editor.ReplayableEditAction(@Editor.ResegFrameAction, t, tMax, [xl;yl]);
        
        Figures.time = t;
        UI.DrawTree(ResegState.primaryTree);
        UI.DrawCells();
        
        if ( bErr )
            if ( ~bResegPaused )
                pauseReseg(hToolbar);
            end
            
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

function bValid = verifySelectedTree()
    global ResegState Figures CellTracks CellFamilies
    
    bValid = true;
    if ( isempty(ResegState) )
        return;
    end
    
    preserveRoots = Families.GetFamilyRoots(CellFamilies(ResegState.primaryTree).rootTrackID);
    validPreserveFam = [CellTracks(preserveRoots).familyID];
    
    if ( any(validPreserveFam == Figures.tree.familyID) )
        return;
    end
    
    msgbox('The selected lineage is not one of the lineages being resegmented!','Incorrect Tree', 'warn');
    
    bValid = false;
end

function cleanupReseg(hToolbar)
    global Figures
    
    [bErr finishTime] = Editor.ReplayableEditAction(@Editor.ResegFinishAction);
    Editor.ReplayableEditAction(@Editor.StopReplayableSubtask, finishTime-1, 'InteractiveResegTask');
    
    set(Figures.cells.handle, 'BusyAction','cancel', 'Interruptible','off');
    set(Figures.tree.handle, 'BusyAction','cancel', 'Interruptible','off');
    
    delete(hToolbar);
end

function playReseg(hToolbar)
    global ResegState
    
    if ( ~verifySelectedTree() )
        return;
    end
    
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
    global ResegState bResegPaused bResegTransition
    if ( isempty(ResegState) )
        return;
    end
    
    if ( isempty(bResegTransition) || bResegTransition )
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
    global Figures ResegState bResegPaused bResegTransition
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
    
    curTime = Figures.time;
    if ( curTime > 1 )
        UI.TimeChange(curTime-1);
    end
    
    Editor.ReplayableEditAction(@Editor.StartReplayableSubtask, 'PauseResegTask');
    
    setPausedToolbarState(hToolbar);
end

function forwardReseg(src,evnt)
    global Figures HashedCells ResegState bResegPaused bResegTransition
    if ( isempty(ResegState) || isempty(bResegPaused) )
%         delete(get(src,'Parent'));
        return;
    end
    
    if ( ~bResegPaused )
        return;
    end
    
    if ( ~verifySelectedTree() )
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
    global Figures ResegState bResegPaused bResegTransition
    
    if ( bResegPaused )
        Editor.ReplayableEditAction(@Editor.StopReplayableSubtask, ResegState.currentTime-1, 'PauseResegTask');
    end
    
    hToolbar = get(src,'Parent');
    cleanupReseg(hToolbar)
end

function setPausedToolbarState(hToolbar)
    global ResegState HashedCells bResegTransition
    
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
    
    bResegTransition = false;
    
    drawnow();
end

function setPlayToolbarState(hToolbar)
    global bResegTransition
    
    hButtons = get(hToolbar, 'Children');
    
    pauseIm = imread('+UI\pause.png');
    set(hButtons(3),'CData',pauseIm, 'TooltipString','Pause Resegmentation');
    
    set(hButtons(4), 'Enable','off');
    set(hButtons(2), 'Enable','off');
    
    set(hButtons(3), 'Enable','on');
    set(hButtons(1), 'Enable','on');
    
    bResegTransition = false;
    
    drawnow();
end

function setProcessingToolbarState(hToolbar)
	global bResegTransition

    hButtons = get(hToolbar, 'Children');
    
    set(hButtons, 'Enable','off');
    
    bResegTransition = true;
    
    drawnow();
end

function hToolbar = addButtons()
    global Figures bResegTransition
    
    bResegTransition = false;
    
%     set(Figures.cells.handle, 'Toolbar','none');
    
    hToolbar = uitoolbar(Figures.cells.handle);
    backIm = imread('+UI\backFrame.png');
    playIm = imread('+UI\play.png');
    pauseIm = imread('+UI\pause.png');
    forwardIm = imread('+UI\forwardFrame.png');
%     revertIm = imread('+UI\revert.png');
    finishIm = imread('+UI\stop.png');
    
    toolHandles = [];
    
    hpt = uipushtool(hToolbar, 'CData',backIm, 'ClickedCallback',@backupReseg, 'TooltipString','Undo 1 Frame', 'Interruptible','off', 'BusyAction','cancel');
    set(hpt, 'Enable','off');
    toolHandles = [toolHandles; hpt];
    
    hpt = uipushtool(hToolbar, 'CData',pauseIm, 'ClickedCallback',@toggleReseg, 'TooltipString','Pause Resegmentation');
    toolHandles = [toolHandles; hpt];
    
    hpt = uipushtool(hToolbar, 'CData',forwardIm, 'ClickedCallback',@forwardReseg, 'TooltipString','Forward 1 Frame', 'Interruptible','off', 'BusyAction','cancel');
    set(hpt, 'Enable','off');
    toolHandles = [toolHandles; hpt];
    
%     uipushtool(hToolbar, 'CData',revertIm, 'ClickedCallback',@abortReseg, 'TooltipString','Revert all changes', 'Separator','on', 'Interruptible','off');
    hpt = uipushtool(hToolbar, 'CData',finishIm, 'ClickedCallback',@finishReseg, 'TooltipString','Finish', 'Separator','on');
    toolHandles = [toolHandles; hpt];
    
    set(hToolbar, 'UserData',toolHandles);
    drawnow();
end
