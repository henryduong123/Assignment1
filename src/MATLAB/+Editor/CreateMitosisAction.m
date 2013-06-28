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
    childHulls = findChildrenHulls(linePoints, time);
    parentHull = findParentHull(childHulls, linePoints, time-1, forceParents);
    
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

function parentHull = findParentHull(childHulls, linePoints, time, forceParents)
    global CONSTANTS CellHulls HashedCells
    
    if ( ~exist('forceParents', 'var') )
        forceParents = [];
    end
    
    midpoint = mean(linePoints,1);
    
    % Forced to choose previous mitosis hull as parent, so just pick the
    % closest
    if ( ~isempty(forceParents) )
        distSq = sum((vertcat(CellHulls(forceParents).centerOfMass) - repmat([midpoint(2) midpoint(1)],length(forceParents),1)).^2, 2);
        [minDist minIdx] = min(distSq);
        parentHull = forceParents(minIdx);
        return;
    end
    
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
    
    if ( any(childHulls == 0) )
        error('Not yet implemented');
    end
    
    if ( childHulls(1) == childHulls(2) )
        % Split: Try for orthogonal to line
        newHulls = splitMitosisHull(childHulls(1), linePoints);
        if ( isempty(newHulls) )
            % TODO: Perhaps try to add a hull in this case
            error('Unable to split hull for mitosis');
        end

        % Mark split hull pieces as user-edited.
        for i=1:length(newHulls)
            newHulls(i).userEdited = 1;
        end

        % Drop old graphedits on a manual split
        Tracker.GraphEditsResetHulls(childHulls(1));

        setHullIDs = zeros(1,length(newHulls));
        setHullIDs(1) = childHulls(1);
        % Just arbitrarily assign clone's hull for now
        childHulls = Hulls.SetHullEntries(setHullIDs, newHulls);
        
        updateLocalTracking(childHulls, time);
    end
    
end

function updateLocalTracking(newHulls, hullTime)
    global HashedCells
    
    lastHulls = [HashedCells{hullTime-1}.hullID];
    Tracker.UpdateTrackingCosts(hullTime-1, lastHulls, newHulls);
        
    if ( hullTime < length(HashedCells) )
        nextHulls = [HashedCells{hullTime+1}.hullID];
        Tracker.UpdateTrackingCosts(hullTime, newHulls, nextHulls);
    end
end

function newHulls = splitMitosisHull(hullID, linePoints)
    global CONSTANTS CellHulls
    
    k = 2;
    newHulls = [];
    
    [r c] = ind2sub(CONSTANTS.imageSize, CellHulls(hullID).indexPixels);
    [kIdx centers] = kmeans([c,r], k, 'start',linePoints, 'EmptyAction','drop');
    
    if ( any(isnan(kIdx)) )
        return;
    end

    connComps = cell(1,k);
    
    for i=1:k
        bIdxPix = (kIdx == i);

        hx = c(bIdxPix);
        hy = r(bIdxPix);

        % If any sub-object is less than 15 pixels then cannot split this
        % hull
        if ( nnz(bIdxPix) < 15 )
            newHulls = [];
            return;
        end
        
        connComps{i} = CellHulls(hullID).indexPixels(bIdxPix);

        imPix = CellHulls(hullID).imagePixels(bIdxPix);
        nh = createNewHullStruct(hx,hy, imPix, CellHulls(hullID).time);
        if ( isempty(nh) )
            newHulls = [];
            return;
        end
        
        newHulls = [newHulls nh];
    end

    % Define an ordering on the hulls selected, COM is unique per component so
    % this gives a deterministic ordering to the components
    [sortCOM, sortIdx] = sortrows(vertcat(newHulls.centerOfMass));
    newHulls = newHulls(sortIdx);
    connComps = connComps(sortIdx);
    
end

function newHull = createNewHullStruct(x,y, imagePixels, time)
    global CONSTANTS
    
    newHull = struct('time', [], 'points', [], 'centerOfMass', [], 'indexPixels', [], 'imagePixels', [], 'deleted', 0, 'userEdited', 0);

    idxPix = sub2ind(CONSTANTS.imageSize, y,x);
    
    newHull.indexPixels = idxPix;
    newHull.imagePixels = imagePixels;
    newHull.centerOfMass = mean([y x], 1);
    newHull.time = time;

    try
        chIdx = convhull(x, y);
    catch excp
        newHull = [];
        return;
    end

    newHull.points = [x(chIdx) y(chIdx)];
end

function hull = findHullNearby(centerPoint, time)
    global CONSTANTS CellHulls HashedCells
    
    hull = 0;
    
    frameHulls = [HashedCells{time}.hullID];
    
    bInHull = Hulls.CheckHullsContainsPoint(centerPoint, CellHulls(frameHulls));
    
    chkHull = frameHulls(bInHull);
    if ( isempty(chkHull) )
        distSq = sum((vertcat(CellHulls(frameHulls).centerOfMass) - repmat([centerPoint(2) centerPoint(1)],length(frameHulls),1)).^2, 2);
        [minDistSq minIdx] = min(distSq);
        
        if ( minDistSq < (CONSTANTS.dMaxCenterOfMass/4)^2 )
            chkHull = frameHulls(minIdx);
        end
        
        chkHull = frameHulls(minIdx);
    elseif ( length(chkHull) > 1 )
        distSq = sum((vertcat(CellHulls(chkHulls).centerOfMass) - repmat([centerPoint(2) centerPoint(1)],length(chkHulls),1)).^2, 2);
        [minDistSq minIdx] = min(distSq);
        
        chkHull = chkHulls(minIdx);
    end
    
    if ( isempty(chkHull) )
        % Try to add a new hull
        return;
%         error('Not yet implemented');
    end
end

