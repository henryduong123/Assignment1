% historyAction = CreateMitosisAction(treeID, time, startPoint, endPoint)
% Edit Action:
% 
% Create user identified mitosis events and add to current tree.

function historyAction = CreateMitosisAction(treeID, time, linePoints)
    global CellFamilies CellTracks HashedCells
    
    if ( time < 2 )
        error('Mitosis event cannot be defined in the first frame');
    end
    
    treeTracks = [CellFamilies(treeID).tracks];
    bMidTracks = (([CellTracks(treeTracks).startTime] < time) & ([CellTracks(treeTracks).endTime] > time));
    
	checkTracks = treeTracks(bMidTracks);
    if ( isempty(checkTracks) )
        error('No valid tracks to add a mitosis onto');
    end
    
    startTimes = [CellTracks(checkTracks).startTime];
    [minTime minIdx] = min(startTimes);
    
    forceParents = [];
    % If a mitosis is specified RIGHT after another one, we have a problem
    % so force old mitosis children into the list
    if ( minTime == time-1 )
        forceParents = arrayfun(@(x)(CellTracks(x).hulls(1)), checkTracks);
    end
    
    % Find or create hulls to define mitosis event
    childHulls = Segmentation.MitosisEditor.FindChildrenHulls(linePoints, time);
    parentHull = Segmentation.MitosisEditor.FindParentHull(childHulls, linePoints, time-1, forceParents);
    
%     costMatrix = Tracker.GetCostMatrix();
    
%     bLeafTrack = arrayfun(@(x)(isempty(x.childrenTracks)), CellTracks(treeTracks));
%     leafTracks = treeTracks(bLeafTrack);
    
    % NOTE: This just makes the tree as balanced as possible, it is probably not correct
    balancedTrack = checkTracks(minIdx);
    parentTrack = Hulls.GetTrackID(parentHull);
    if ( balancedTrack ~= parentTrack )
        Tracks.LockedChangeLabel(parentTrack, balancedTrack, time-1);
    end
    
    childTrack = Hulls.GetTrackID(childHulls(1));
    if ( balancedTrack ~= childTrack )
        Tracks.LockedChangeLabel(childTrack, balancedTrack, time);
    end
    
    childTrack = Hulls.GetTrackID(childHulls(2));
    if ( Helper.CheckLocked(childTrack) )
        error('Not yet implemented: Locked "addMitosis"');
    else
        Families.AddMitosis(childTrack, balancedTrack, time);
    end
    
    % TODO: Make this respect the endTime from start of state
    if ( time < length(HashedCells) )
        childTrack = Hulls.GetTrackID(childHulls(2));
        Helper.PushTrackToFrame(childTrack, length(HashedCells));
    end
    
    historyAction = 'Push';
end
