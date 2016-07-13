% historyAction = LockedAddMitosisAction(parentTrack, leftChild, siblingTrack, time)
% Edit Action:
% 
% Add siblingTrack as a mitosis event from parentTrack at time. If
% leftChild is non-empty also change its label to the parent track before
% adding the mitosis. Try to minimize locked tree structure changes

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
%     Copyright 2016 Drexel University
%
%     This file is part of LEVer - the tool for stem cell lineaging. See
%     http://n2t.net/ark:/87918/d9rp4t for details
% 
%     LEVer is free software: you can redistribute it and/or modify
%     it under the terms of the GNU General Public License as published by
%     the Free Software Foundation, either version 3 of the License, or
%     (at your option) any later version.
% 
%     LEVer is distributed in the hope that it will be useful,
%     but WITHOUT ANY WARRANTY; without even the implied warranty of
%     MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
%     GNU General Public License for more details.
% 
%     You should have received a copy of the GNU General Public License
%     along with LEVer in file "gnu gpl v3.txt".  If not, see 
%     <http://www.gnu.org/licenses/>.
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


function historyAction = LockedAddMitosisAction(parentTrack, leftChildTrack, siblingTrack, time)
    global CellTracks
    
    [bParentLock bChildrenLock bCanAdd] = Families.CheckLockedAddMitosis(parentTrack, leftChildTrack, siblingTrack, time);
    if ( ~bCanAdd )
        error(['Cannot perform a locked add mitosis on ' num2str(parentTrack) '<- ' num2str([leftChildTrack siblingTrack])]);
    end
    
    if ( isempty(leftChildTrack) )
        if ( bChildrenLock )
            % Do a full subtree add if sibling is locked and mitosis is at root of tree
            siblingStart = CellTracks(siblingTrack).startTime;
            if ( (siblingStart == time) && isempty(CellTracks(siblingTrack).parentTrack) )
                Families.AddMitosis(siblingTrack, parentTrack);

                historyAction = 'Push';
                return;
            end
        end
    else
        Tracks.LockedChangeLabel(leftChildTrack, parentTrack, time);
    end
    
    % Pull the sibling hull we want out of track
    [siblingTrack droppedTracks] = removeSingleHull(siblingTrack, time);
    if ( bChildrenLock(1) && ~isempty(droppedTracks) )
        error('Locked add mitosis has dropped structure on locked sibling tree');
    end
    
    Tracker.GraphEditAddMitosis(parentTrack, siblingTrack, time);
    droppedTracks = Families.AddMitosis(siblingTrack, parentTrack);
    
    historyAction = 'Push';
end

function [newTrack droppedTracks] = removeSingleHull(trackID, time)
    global CellTracks CellFamilies
    
    droppedTracks = [];
    newTrack = trackID;
    if ( CellTracks(trackID).startTime == time )
        % Leave trackID the same and drop the rest of the track
        oldDropped = Families.RemoveFromTreePrune(trackID, time+1);
    else
        trackHull = Helper.GetNearestTrackHull(trackID, time, 0);
        if ( trackHull == 0 )
            error('Sibling track must have hull on specified frame');
        end

        droppedTracks = Tracks.RemoveHullFromTrack(trackHull);
        newFam = Families.NewCellFamily(trackHull);

        newTrack = CellFamilies(newFam).rootTrackID;
    end
end
