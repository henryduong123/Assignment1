% historyAction = SwitchParent(Family ID, trackA, trackB, time)
% Edit Action:
% Switches Parents
% Toggles lock on familyID
% Context Swap Labels 
% Toggle lock on family ID

function historyAction = SwitchParent(familyID,trackID,newTrackID, time)
 global CellFamilies
 global Figures
 trackA = trackID;
 trackB = newTrackID;
    Tracker.GraphEditSetEdge(trackA, trackB, time);
    Tracker.GraphEditSetEdge(trackB, trackA, time);
 % Unlock Tree Lock
    if ( isempty(CellFamilies(familyID).bLocked) )
        CellFamilies(familyID).bLocked = 0;
    end
    
    bIsLocked = CellFamilies(familyID).bLocked;
    Helper.SetTreeLocked(familyID, ~bIsLocked);
    % Swap two cells together 
     
    
    bLocked = Helper.CheckTreeLocked([trackA trackB]);
    if ( any(bLocked) )
        Tracks.LockedSwapLabels(trackA, trackB, time);
    else
        Tracks.SwapLabels(trackA, trackB, time);
    end
 % Relock Tree Lock    
    if ( isempty(CellFamilies(familyID).bLocked) )
    CellFamilies(familyID).bLocked = 0;
    end
   
    bIsLocked = CellFamilies(familyID).bLocked;
    Helper.SetTreeLocked(familyID, ~bIsLocked);
    UI.DrawTree(Figures.tree.familyID);
    historyAction = 'Push';
end