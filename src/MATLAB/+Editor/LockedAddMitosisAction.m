% historyAction = LockedAddMitosisAction(parentTrack, leftChild, siblingTrack, time)
% Edit Action:
% 
% Add siblingTrack as a mitosis event from parentTrack at time. If
% leftChild is non-empty also change its label to the parent track before
% adding the mitosis. Try to minimize locked tree structure changes

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
