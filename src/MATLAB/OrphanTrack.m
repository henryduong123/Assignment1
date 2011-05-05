%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
%     This file is part of LEVer.exe
%     (C) 2011 Andrew Cohen, Eric Wait and Mark Winter
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% A much simlified version of RemoveFromTree made specifically to orphan
% entire subtrees rooted at trackID.  Also specifically preserves track
% labels because no tracks are split in the process.
function OrphanTrack(trackID, bCombineSibling)
    global CellTracks
    
    if ( ~exist('bCombineSibling', 'var') )
        bCombineSibling = 0;
    end
    
    if ( isempty(CellTracks(trackID).parentTrack) )
        return;
    end
    
    oldFamilyID = CellTracks(trackID).familyID;
    newFamilyID = NewCellFamily(CellTracks(trackID).hulls(1),CellTracks(trackID).startTime);
    
    % Put track and it's children into the new family
    ChangeTrackAndChildrensFamily(oldFamilyID, newFamilyID, trackID);
    
    if ( bCombineSibling && ~isempty(CellTracks(trackID).siblingTrack) )
        CombineTrackWithParent(CellTracks(trackID).siblingTrack);
    end
    
    CellTracks(trackID).parentTrack = [];
    CellTracks(trackID).siblingTrack = [];
end