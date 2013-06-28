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
    
    % Find or create hulls to define mitosis event
    childHulls = findChildrenHulls(linePoints, time);
    parentHull = findParentHull(childHulls, linePoints, time-1);
    
    startTimes = [CellTracks(checkTracks).startTime];
    [minTime minIdx] = min(startTimes);
    
    % If a mitosis is specified RIGHT after another one, we have a problem
    if ( minTime == time-1 )
        bMatchesParent = arrayfun(@(x)(parentHull == CellTracks(x).hulls(1)), checkTracks);
        if ( ~any(bMatchesParent) )
            error('No valid tracks to add a mitosis onto');
        end
        
        minIdx = find(bMatchesParent, 1, 'first');
    end
    
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

function parentHull = findParentHull(childHulls, linePoints, time)
    global CONSTANTS CellHulls HashedCells
    
    midpoint = mean(linePoints,1);
    
    frameHulls = [HashedCells{time}.hullID];
    distSq = sum((vertcat(CellHulls(frameHulls).centerOfMass) - repmat([midpoint(2) midpoint(1)],length(frameHulls),1)).^2, 2);
    
    chkHulls = frameHulls(distSq < (CONSTANTS.dMaxCenterOfMass)^2);
    
    mitosisPoints = vertcat(CellHulls(childHulls).points);
    mitosisCVIdx = convhull(mitosisPoints(:,1), mitosisPoints(:,2));
    mitosisPoints = mitosisPoints(mitosisCVIdx,:);
    
    pointCounts = zeros(1,length(chkHulls));
    
    for i=1:length(chkHulls)
        [r c] = ind2sub(CONSTANTS.imageSize, CellHulls(chkHulls(i)).indexPixels);
        bContainsPoints = inpolygon(c,r, mitosisPoints(:,1), mitosisPoints(:,2));
        pointCounts(i) = nnz(bContainsPoints);
    end
    
    [maxPoints maxIdx] = max(pointCounts);
    if ( maxPoints > 0 )
        parentHull = chkHulls(maxIdx);
        return;
    end
    
    % Add a new parent hull
    error('Not yet implemented');
end

function childHulls = findChildrenHulls(linePoints, time)
    childHulls = zeros(1,2);

    childHulls(1) = findHullNearby(linePoints(1,:), time);
    childHulls(2) = findHullNearby(linePoints(2,:), time);
    
    if ( childHulls(1) == childHulls(2) )
        % Split: Try for orthogonal to line
        error('Split not yet implemented');
    end
    
end

function hull = findHullNearby(centerPoint, time)
    global CONSTANTS CellHulls HashedCells
    
    frameHulls = [HashedCells{time}.hullID];
    
    bInHull = Hulls.CheckHullsContainsPoint(centerPoint, CellHulls(frameHulls));
    
    hull = frameHulls(bInHull);
    if ( isempty(hull) )
        distSq = sum((vertcat(CellHulls(frameHulls).centerOfMass) - repmat([centerPoint(2) centerPoint(1)],length(frameHulls),1)).^2, 2);
        [minDistSq minIdx] = min(distSq);
        
        if ( minDistSq < (CONSTANTS.dMaxCenterOfMass/2)^2 )
            hull = frameHulls(minIdx);
        end
        
        hull = frameHulls(minIdx);
    elseif ( length(hull) > 1 )
        distSq = sum((vertcat(CellHulls(chkHulls).centerOfMass) - repmat([centerPoint(2) centerPoint(1)],length(chkHulls),1)).^2, 2);
        [minDistSq minIdx] = min(distSq);
        
        hull = chkHulls(minIdx);
    end
    
    if ( isempty(hull) )
        % Try to add a new hull
        error('Not yet implemented');
    end
end

