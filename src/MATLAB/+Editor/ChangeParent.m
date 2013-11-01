% historyAction = ChangeParent(Family ID, trackA, trackB, time)
% Edit Action:
% Switches Parents
% Toggles lock on familyID
% Context Swap Labels 
% Toggle lock on family ID
% Maria Enokian
function historyAction = ChangeParent(familyID,trackID,newTrackID, time)
% Initialized variables
global CellFamilies  CellTracks  Figures
trackID = CellTracks(trackID).parentTrack;
 trackA = trackID;
 trackB = newTrackID;
 Ntime = CellTracks(trackID).endTime; 
    Tracker.GraphEditSetEdge(trackA, trackB, Ntime);
    Tracker.GraphEditSetEdge(trackB, trackA, Ntime);
  
 % This will unlock the tree and if the cell family is locked it will
 % unlock it but otherwise it will lock it.
    if ( isempty(CellFamilies(familyID).bLocked) )
        CellFamilies(familyID).bLocked = 0;
    end
    
    bIsLocked = CellFamilies(familyID).bLocked;
    Helper.SetTreeLocked(familyID, ~bIsLocked);
    % This will swap the two Parents together to correct the mitosis 
    bLocked = Helper.CheckTreeLocked([trackA trackB]);
    if ( any(bLocked) )
        Tracks.LockedSwapLabels(trackA, trackB, Ntime);
    else
        Tracks.SwapLabels(trackA, trackB, Ntime);
    end
 % This will unlock the tree and if the cell family is locked it will
 % unlock it but otherwise it will lock it.   
    if ( isempty(CellFamilies(familyID).bLocked) )
    CellFamilies(familyID).bLocked = 0;
    end
   
    bIsLocked = CellFamilies(familyID).bLocked;
    Helper.SetTreeLocked(familyID, ~bIsLocked);
    UI.DrawTree(Figures.tree.familyID);
    historyAction = 'Push';
end