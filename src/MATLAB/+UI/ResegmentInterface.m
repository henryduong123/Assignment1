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
    
    [bErr bFinished] = Editor.ReplayableEditAction(@Editor.ResegPlayAction, ResegState.currentTime);
    if ( bFinished )
        cleanupReseg(hToolbar);
    end
end

function cleanupReseg(hToolbar)
    [bErr finishTime] = Editor.ReplayableEditAction(@Editor.ResegFinishAction);
    Editor.ReplayableEditAction(@Editor.StopReplayableSubtask, finishTime-1, 'InteractiveResegTask');
    
    delete(hToolbar);
end

function toggleReseg(src,evnt)
    global Figures HashedCells ResegState bResegPaused
    if ( isempty(ResegState) )
%         delete(get(src,'Parent'));
        return;
    end
    
    playIm = imread('+UI\play.png');
    pauseIm = imread('+UI\pause.png');
    
    hToolbar = get(src, 'Parent');
    if ( bResegPaused )
        setPlayToolbarState(hToolbar);
        set(src,'CData',pauseIm, 'TooltipString','Pause Resegmentation');
        
        % Prepare to start playing resegmentation again, consolidate pause edits
        Editor.ReplayableEditAction(@Editor.StopReplayableSubtask, ResegState.currentTime-1, 'PauseResegTask');
        [bErr bFinished] = Editor.ReplayableEditAction(@Editor.ResegPlayAction, ResegState.currentTime);
        if ( bFinished )
            cleanupReseg(hToolbar);
            return;
        end
    else
        set(src,'CData',playIm, 'TooltipString','Continue Resegmentation');
        
        % Pause resegmentation, make new subtask for edits while paused
        Editor.ReplayableEditAction(@Editor.StartReplayableSubtask, 'PauseResegTask');
        bErr = Editor.ReplayableEditAction(@Editor.ResegPauseAction);
        
        setPausedToolbarState(hToolbar);
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
    
    xlims = get(Figures.tree.axesHandle,'XLim');
    hold(Figures.tree.axesHandle,'on');
    plot(Figures.tree.axesHandle, [xlims(1), xlims(2)],[ResegState.currentTime-1, ResegState.currentTime-1], '-b');
    hold(Figures.tree.axesHandle,'off');
    
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
    
    Editor.ReplayableEditAction(@Editor.StopReplayableSubtask, ResegState.currentTime-1, 'PauseResegTask');
    
    [bErr bFinished] = Editor.ReplayableEditAction(@Editor.ResegForwardAction);
    if ( bFinished )
        cleanupReseg(hToolbar)
        return;
    end
    
    xlims = get(Figures.tree.axesHandle,'XLim');
    hold(Figures.tree.axesHandle,'on');
    plot(Figures.tree.axesHandle, [xlims(1), xlims(2)],[ResegState.currentTime-1, ResegState.currentTime-1], '-b');
    hold(Figures.tree.axesHandle,'off');
    
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
end

function setPlayToolbarState(hToolbar)
    hButtons = get(hToolbar, 'Children');
    
    set(hButtons(4), 'Enable','off');
    set(hButtons(2), 'Enable','off');
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
    
    hpt = uipushtool(hToolbar, 'CData',backIm, 'ClickedCallback',@backupReseg, 'TooltipString','Undo 1 Frame');
    set(hpt, 'Enable','off');
    
    uipushtool(hToolbar, 'CData',pauseIm, 'ClickedCallback',@toggleReseg, 'TooltipString','Pause Resegmentation');
    hpt = uipushtool(hToolbar, 'CData',forwardIm, 'ClickedCallback',@forwardReseg, 'TooltipString','Forward 1 Frame');
    set(hpt, 'Enable','off');
    
%     uipushtool(hToolbar, 'CData',revertIm, 'ClickedCallback',@abortReseg, 'TooltipString','Revert all changes', 'Separator','on');
    uipushtool(hToolbar, 'CData',finishIm, 'ClickedCallback',@finishReseg, 'TooltipString','Finish', 'Separator','on');
end
