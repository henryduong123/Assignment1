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
    
    Editor.ReplayableEditAction(@Editor.StartReplayableSubtask, 'InteractiveResegTask');
    
    [bErr bFinished] = Editor.ReplayableEditAction(@Editor.ResegInitializeAction, preserveFam, 2);
    if ( bErr || bFinished )
        Editor.ReplayableEditAction(@Editor.StopReplayableSubtask, Figures.time, 'InteractiveResegTask');
        delete(hToolbar);
    end
end

function toggleReseg(src,evnt)
    global Figures ResegState bResegPaused
    if ( isempty(ResegState) )
%         delete(get(src,'Parent'));
        return;
    end
    
    playIm = imread('+UI\play.png');
    pauseIm = imread('+UI\pause.png');
    
    if ( bResegPaused )
        hToolbar = get(src, 'Parent');
        hButtons = get(hToolbar, 'Children');
        set(hButtons(3), 'Enable','off');
        set(src,'CData',pauseIm, 'TooltipString','Pause Resegmentation');
        
        % Prepare to start playing resegmentation again, consolidate pause edits
        Editor.ReplayableEditAction(@Editor.StopReplayableSubtask, ResegState.currentTime-1, 'PauseResegTask');
        [bErr bFinished] = Editor.ReplayableEditAction(@Editor.ResegPlayAction, ResegState.currentTime);
        if ( bFinished )
            Editor.ReplayableEditAction(@Editor.StopReplayableSubtask, Figures.time,'InteractiveResegTask');
            delete(get(src,'Parent'));
        end
    else
        set(src,'CData',playIm, 'TooltipString','Continue Resegmentation');
        
        hToolbar = get(src, 'Parent');
        hButtons = get(hToolbar, 'Children');
        if ( ~Editor.StackedHistory.CanUndo() )
            set(hButtons(3), 'Enable','off');
        else
            set(hButtons(3), 'Enable','on');
        end
        
        % Pause resegmentation, make new subtask for edits while paused
        Editor.ReplayableEditAction(@Editor.StartReplayableSubtask, 'PauseResegTask');
        bErr = Editor.ReplayableEditAction(@Editor.ResegPauseAction);
    end
end

function backupReseg(src,evnt)
    global Figures ResegState bResegPaused
    if ( isempty(ResegState) || isempty(bResegPaused) )
%         delete(get(src,'Parent'));
        return;
    end
    
    if ( ~bResegPaused )
        return;
    end
    
    resegLevel = Editor.StackedHistory.GetDepth()-1;
    if ( ~Editor.StackedHistory.CanUndo(resegLevel) )
        return;
    end
    
    Editor.ReplayableEditAction(@Editor.DropReplayableSubtask, 'PauseResegTask');
    Editor.ReplayableEditAction(@Editor.Top);
    
    bErr = Editor.ReplayableEditAction(@Editor.ResegBackAction);
    if ( ~Editor.StackedHistory.CanUndo() )
        set(src, 'Enable','off');
    end
    
    xlims = get(Figures.tree.axesHandle,'XLim');
    hold(Figures.tree.axesHandle,'on');
    plot(Figures.tree.axesHandle, [xlims(1), xlims(2)],[ResegState.currentTime-1, ResegState.currentTime-1], '-b');
    hold(Figures.tree.axesHandle,'off');
    
    Editor.ReplayableEditAction(@Editor.StartReplayableSubtask, 'PauseResegTask');
end

function finishReseg(src,evnt)
    global Figures bResegPaused
    
    if ( bResegPaused )
        Editor.ReplayableEditAction(@Editor.StopReplayableSubtask, Figures.time, 'PauseResegTask');
    end
    
    Editor.ReplayableEditAction(@Editor.ResegFinishAction);
    Editor.ReplayableEditAction(@Editor.StopReplayableSubtask, Figures.time, 'InteractiveResegTask');
    
%     set(Figures.cells.handle, 'Toolbar','figure');
    delete(get(src,'Parent'));
end

function hToolbar = addButtons()
    global Figures
    
%     set(Figures.cells.handle, 'Toolbar','none');
    
    hToolbar = uitoolbar(Figures.cells.handle);
    backIm = imread('+UI\backFrame.png');
    playIm = imread('+UI\play.png');
    pauseIm = imread('+UI\pause.png');
%     forwardIm = imread('+UI\forwardFrame.png');
%     revertIm = imread('+UI\revert.png');
    finishIm = imread('+UI\stop.png');
    
    hpt = uipushtool(hToolbar, 'CData',backIm, 'ClickedCallback',@backupReseg, 'TooltipString','Undo 1 Frame');
    set(hpt, 'Enable','off');
    
    uipushtool(hToolbar, 'CData',pauseIm, 'ClickedCallback',@toggleReseg, 'TooltipString','Pause Resegmentation');
%     uipushtool(hToolbar, 'CData',forwardIm, 'TooltipString','Forward 1 Frame');
    
%     uipushtool(hToolbar, 'CData',revertIm, 'ClickedCallback',@abortReseg, 'TooltipString','Revert all changes', 'Separator','on');
    uipushtool(hToolbar, 'CData',finishIm, 'ClickedCallback',@finishReseg, 'TooltipString','Finish');
end
