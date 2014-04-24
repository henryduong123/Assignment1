function MitosisEditInterface()
    global Figures CellFamilies CellTracks CellHulls HashedCells MitosisEditStruct
    
    Figures.cells.editMode = 'mitosis';
    
    editTree = Figures.tree.familyID;
    
    MitosisEditStruct.editingHullID = [];
    MitosisEditStruct.selectedTrackID = [];
    
    MitosisEditStruct.selectCosts = [];
    MitosisEditStruct.selectPath = [];
    
    rootTrackID = CellFamilies(editTree).rootTrackID;
    firstHull = CellTracks(rootTrackID).hulls(1);
    
    UI.MitosisSelectTrackingCell(rootTrackID,CellHulls(firstHull).time, true);
    
    % Order matters here, we want the Init action to be part of the subtask
    Editor.ReplayableEditAction(@Editor.StartReplayableSubtask, 'MitosisEditTask');
    Editor.ReplayableEditAction(@Editor.MitosisEditInitializeAction, editTree, length(HashedCells));
    
    hToolbar = addButtons();
end

function cleanupMitosisInterface(hToolbar)
    global Figures MitosisEditStruct
    Figures.cells.editMode = 'normal';
    
    MitosisEditStruct = [];
    
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
