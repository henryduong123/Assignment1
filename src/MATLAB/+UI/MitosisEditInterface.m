function MitosisEditInterface()
    global Figures CellFamilies HashedCells
    
    Figures.cells.editMode = 'mitosis';
    
    editTree = Figures.tree.familyID;
    rootTrack = CellFamilies(editTree).rootTrackID;
    
    % Order matters here, we want the Init action to be part of the subtask
    Editor.ReplayableEditAction(@Editor.StartReplayableSubtask, 'MitosisEditTask');
    Editor.ReplayableEditAction(@Editor.MitosisEditInitializeAction, rootTrack, length(HashedCells));
    
    UI.DrawTree(editTree);
    UI.DrawCells();
    
    hToolbar = addButtons();
end

function cleanupMitosisInterface(hToolbar)
    global Figures
    Figures.cells.editMode = 'normal';
    
    Editor.ReplayableEditAction(@Editor.StopReplayableSubtask, 1, 'MitosisEditTask');
    
    UI.DrawTree();
    UI.DrawCells();
    
    delete(hToolbar);
end

function finishMitosisEdit(src, evnt)
    hToolbar = get(src,'Parent');
    cleanupMitosisInterface(hToolbar)
end

function hToolbar = addButtons()
    global Figures
    
    hToolbar = uitoolbar(Figures.cells.handle);
    finishIm = imread('+UI\stop.png');
    
    uipushtool(hToolbar, 'CData',finishIm, 'ClickedCallback',@finishMitosisEdit, 'TooltipString','Finish Tree Mitosis Edits');
end