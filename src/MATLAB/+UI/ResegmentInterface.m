function ResegmentInterface()
    global Figures CellFamilies CellTracks ResegState
    
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
    
    preserveFam = [CellTracks(checkCells).familyID];
    
    hToolbar = addButtons();
    
    [bErr bFinished] = Editor.ReplayableEditAction(@Editor.ResegInitializeAction, preserveFam, 2);
    if ( bErr || bFinished )
        delete(hToolbar);
    end
end

function toggleReseg(src,evnt)
    global ResegState
    if ( isempty(ResegState) )
%         delete(get(src,'Parent'));
        return;
    end
    
    playIm = imread('+UI\play.png');
    pauseIm = imread('+UI\pause.png');
    
    if ( ResegState.bPaused )
        set(src,'CData',pauseIm, 'TooltipString','Pause Resegmentation');
        [bErr bFinished] = Editor.ReplayableEditAction(@Editor.ResegPlayAction);
        if ( bFinished )
             delete(get(src,'Parent'));
        end
    else
        set(src,'CData',playIm, 'TooltipString','Continue Resegmentation');
        bErr = Editor.ReplayableEditAction(@Editor.ResegPauseAction);
    end
end

function backupReseg(src,evnt)
    global ResegState
    if ( isempty(ResegState) )
%         delete(get(src,'Parent'));
        return;
    end
    
    if ( ~ResegState.bPaused )
        return;
    end
    
    bErr = Editor.ReplayableEditAction(@Editor.ResegBackAction);
end

function finishReseg(src,evnt)
    global Figures
    
    Editor.ReplayableEditAction(@Editor.ResegFinishAction);
    
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
    
    uipushtool(hToolbar, 'CData',backIm, 'ClickedCallback',@backupReseg, 'TooltipString','Undo 1 Frame');
    uipushtool(hToolbar, 'CData',pauseIm, 'ClickedCallback',@toggleReseg, 'TooltipString','Pause Resegmentation');
%     uipushtool(hToolbar, 'CData',forwardIm, 'TooltipString','Forward 1 Frame');
    
%     uipushtool(hToolbar, 'CData',revertIm, 'ClickedCallback',@abortReseg, 'TooltipString','Revert all changes', 'Separator','on');
    uipushtool(hToolbar, 'CData',finishIm, 'ClickedCallback',@finishReseg, 'TooltipString','Finish');
end
