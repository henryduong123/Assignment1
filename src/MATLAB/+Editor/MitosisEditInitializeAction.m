% historyAction = MitosisEditInitializeAction(treeID, endTime)
% Edit Action:
% 
% Initialize mitosis editing state

function historyAction = MitosisEditInitializeAction(treeID, endTime)
    global CellFamilies
    
    rootTrack = CellFamilies(treeID).rootTrackID;
    
    if ( ~CellFamilies(treeID).bLocked )
        Helper.DropSubtree(rootTrack);
    end
    
    CellFamilies(treeID).bLocked = 1;
    
    historyAction = 'Push';
end
