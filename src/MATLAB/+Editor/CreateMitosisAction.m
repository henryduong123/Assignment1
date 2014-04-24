% historyAction = CreateMitosisAction(treeID, time, startPoint, endPoint)
% Edit Action:
% 
% Create user identified mitosis events and add to current tree.

function historyAction = CreateMitosisAction(trackID, dirFlag, treeID, time, linePoints)
    global CellFamilies CellTracks HashedCells
    
    if ( time < 2 )
        error('Mitosis event cannot be defined in the first frame');
    end
    
    treeTracks = [CellFamilies(treeID).tracks];
    
    bInTracks = Helper.CheckInTracks(time, treeTracks, 0, 0);
	checkTracks = treeTracks(bInTracks);
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
    
    linePoints = clipToImage(linePoints);
    
    
    % Find or create hulls to define mitosis event
    childHulls = Segmentation.MitosisEditor.FindChildrenHulls(linePoints, time);
    parentHull = Segmentation.MitosisEditor.FindParentHull(childHulls, linePoints, time-1, forceParents);
    
%     costMatrix = Tracker.GetCostMatrix();
    
%     bLeafTrack = arrayfun(@(x)(isempty(x.childrenTracks)), CellTracks(treeTracks));
%     leafTracks = treeTracks(bLeafTrack);

    Helper.SetTreeLocked(treeID, 0);
    
    % NOTE: This just makes the tree as balanced as possible, it is probably not correct
    balancedTrack = checkTracks(minIdx);
    parentTrack = Hulls.GetTrackID(parentHull);
    
    % TODO: Don't change things up if parentTrack is already complete and on
    % the correct family
    if ( CellTracks(parentTrack).familyID == treeID )
        balancedTrack = parentTrack;
    end
    
    if ( ~isempty(trackID) && dirFlag > 0 )
        balancedTrack = trackID;
    else
        error('Adding mitosis event above edit is currently unsupported!');
    end
    
    if ( balancedTrack ~= parentTrack )
        attemptLockedChangeLabel(parentTrack, balancedTrack, time-1);
    end
    
    childTrack = Hulls.GetTrackID(childHulls(1));
    if ( balancedTrack ~= childTrack )
        attemptLockedChangeLabel(childTrack, balancedTrack, time);
    end
    
    childTrack = Hulls.GetTrackID(childHulls(2));
    if ( Helper.CheckTreeLocked(childTrack) )
        error('Not yet implemented: Locked "addMitosis"');
    else
        Families.AddMitosis(childTrack, balancedTrack, time);
    end
    
    % TODO: Make this respect the endTime from start of state
    if ( time < length(HashedCells) )
        for i=1:2
            childTrack = Hulls.GetTrackID(childHulls(i));
            Helper.DropSubtree(childTrack);
        end
    end
    
    Helper.SetTreeLocked(treeID, 1);
    
    historyAction = 'Push';
end

function attemptLockedChangeLabel(changeTrack, desiredTrack, time)
    if ( Helper.CheckTreeLocked(changeTrack) )
        Tracks.LockedChangeLabel(changeTrack, desiredTrack, time);
    else
        Tracks.ChangeLabel(changeTrack, desiredTrack, time);
    end
end

function newPoints = clipToImage(linePoints)
    global CONSTANTS
    
    newPoints = linePoints;
    newPoints(:,1) = min(newPoints(:,1), repmat(CONSTANTS.imageSize(2),size(linePoints,1),1));
    newPoints(:,2) = min(newPoints(:,2), repmat(CONSTANTS.imageSize(1),size(linePoints,1),1));
    
    newPoints(:,1) = max(newPoints(:,1), repmat(1,size(linePoints,1),1));
    newPoints(:,2) = max(newPoints(:,2), repmat(1,size(linePoints,1),1));
end

