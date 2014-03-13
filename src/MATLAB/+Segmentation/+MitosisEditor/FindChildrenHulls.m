
function childHulls = FindChildrenHulls(linePoints, time)
    childHulls = zeros(1,2);

    childHulls = addMergeSegmentations(childHulls, linePoints, time);
    if ( childHulls(1) == childHulls(2) )
        % Split: Try for orthogonal to line
        newHulls = splitMitosisHull(childHulls(1), linePoints);
        if ( isempty(newHulls) )
            % TODO: Perhaps try to add a hull in this case
            newHulls = splitMitosisHull(childHulls(1), linePoints, 1);
%             error('Unable to add or split for mitosis event.');
%             return;
        end

        % Mark split hull pieces as user-edited.
        for i=1:length(newHulls)
            newHulls(i).userEdited = true;
        end

        setHullIDs = zeros(1,length(newHulls));
        setHullIDs(1) = childHulls(1);
        % Just arbitrarily assign clone's hull for now
        childHulls = Hulls.SetHullEntries(setHullIDs, newHulls);
    end
    
    childDist = getHullDistance(childHulls, linePoints);
    [minDist minIdx] = min(childDist,[],2);
    if ( minIdx(1) == 2 )
        childHulls = childHulls([2 1]);
    end
    
    if ( any(childHulls == 0) )
        error('Not all child hulls are valid!');
    end
    
    updateLocalTracking(childHulls, time);
end

function newHulls = splitMitosisHull(hullID, linePoints, bForcePoints)
    global CONSTANTS CellHulls
    
    if ( ~exist('bForcePoints','var') )
        bForcePoints = false;
    end
    
    k = 2;
    newHulls = [];
    
    mitVec = (linePoints(2,:) - linePoints(1,:));
    
    mitVec = mitVec / norm(mitVec);
    
    [r c] = ind2sub(CONSTANTS.imageSize, CellHulls(hullID).indexPixels);
    
    if ( bForcePoints )
        distSq = ((c-linePoints(1,1)).^2 + (r-linePoints(1,2)).^2);
        distSq = [distSq ((c-linePoints(2,1)).^2 + (r-linePoints(2,2)).^2)];
        [minDist kIdx] = min(distSq,[],2);
    else
        [kIdx centers] = kmeans([c,r], k, 'start',linePoints, 'EmptyAction','drop');
    end
    
    if ( any(isnan(kIdx)) )
        return;
    end

    connComps = cell(1,k);
    
    for i=1:k
        bIdxPix = (kIdx == i);

        hx = c(bIdxPix);
        hy = r(bIdxPix);

        % If any sub-object is less than 15 pixels then cannot split this hull
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
    
    splitVec = (newHulls(2).centerOfMass - newHulls(1).centerOfMass);
    splitVec = [splitVec(2) splitVec(1)] / norm(splitVec);
    
    % Make sure we're within about 45 degrees of the line
    dirCos = abs(dot(splitVec, mitVec));
    if ( dirCos < 0.75 )
        newHulls = [];
        return;
    end

    % Define an ordering on the hulls selected, COM is unique per component so
    % this gives a deterministic ordering to the components
    [sortCOM, sortIdx] = sortrows(vertcat(newHulls.centerOfMass));
    newHulls = newHulls(sortIdx);
    connComps = connComps(sortIdx);
end

function newHulls = addMergeSegmentations(childHulls, linePoints, time)
    newHulls = zeros(size(childHulls));    
    
    for i=1:length(childHulls)
        childHulls(i) = findHullContainsPoint(linePoints(i,:), time);
        if ( childHulls(i) > 0 )
            newHulls(i) = childHulls(i);
            continue;
        end
        
        chkPoint = linePoints(i,:);
        objs = partialSegObjs(chkPoint, time);
        
        newHulls(i) = mergeOverlapping(objs, chkPoint, time);
    end
    
    for i=1:length(childHulls)
        newHulls(i) = findHullContainsPoint(linePoints(i,:), time);
    end
end

% This function finds any hulls overlapping the chkPoint and returns it,
% will also merge this hull with overlapping hulls if necessary
function hullID = mergeOverlapping(objs, chkPoint, time)
    global CONSTANTS CellHulls HashedCells
    
    hullID = 0;
    frameHulls = [HashedCells{time}.hullID];
    
    bInHull = false(length(objs),1);
    for i=1:length(objs)
        bInHull(i) = inpolygon(chkPoint(1), chkPoint(2), objs(i).points(:,1), objs(i).points(:,2));
    end
    
    if ( ~any(bInHull) )
        hullID = addPointHullEntry(chkPoint, time);
        return;
    end
    
    chkObjs = objs(bInHull);
    
    objCOM = zeros(length(chkObjs),2);
    for i=1:length(chkObjs)
        [r c] = ind2sub(CONSTANTS.imageSize, chkObjs(i).indPixels);
        objCOM = mean([r c], 1);
    end
    
    distSq = sum((objCOM - repmat([chkPoint(2) chkPoint(1)],length(chkObjs),1)).^2, 2);
    [minDistSq minIdx] = min(distSq);
    
    newObj = chkObjs(minIdx);
    
    [r c] = ind2sub(CONSTANTS.imageSize, newObj.indPixels);
    newHullEntry = createNewHullStruct(c, r, newObj.imPixels, time);
    
    bMergeHulls = arrayfun(@(x)(nnz(ismember(newHullEntry.indexPixels,CellHulls(x).indexPixels)) > 5), frameHulls);
    mergeHulls = frameHulls(bMergeHulls);
    
    rmTracks = Hulls.GetTrackID(mergeHulls);
    bLockedTracks = Helper.CheckTreeLocked(rmTracks);
    
    mergeHulls = mergeHulls(~bLockedTracks);
    if ( ~isempty(mergeHulls) )
        hullID = mergeHullValues(mergeHulls(1), newHullEntry);
        for i=2:length(mergeHulls)
            rmHullEntry = CellHulls(mergeHulls(i));
            mergeHullValues(mergeHulls(1), rmHullEntry);
            
            Tracks.RemoveHullFromTrack(mergeHulls(i));
            Hulls.ClearHull(mergeHulls(i));
        end
        
        subTracks = rmTracks(bLockedTracks);
        for i=1:length(subTracks)
            subtractHulls(hullID, subTracks(i));
        end
        return;
    end
    
    newObj = Segmentation.ForceDisjointSeg(newObj, time, chkPoint);
    
    if ( isempty(newObj) )
        hullID = addPointHullEntry(chkPoint, time);
        return;
    end
    
    hullID = addHullEntry(newObj, time);
end

function outHullID = mergeHullValues(hullID, mergeStruct)
    global CONSTANTS CellHulls
    
    outHullID = hullID;
    
    [dump, idxA, idxB] = union(CellHulls(hullID).indexPixels, mergeStruct.indexPixels);
    CellHulls(hullID).indexPixels = [CellHulls(hullID).indexPixels(idxA); mergeStruct.indexPixels(idxB)];
    CellHulls(hullID).imagePixels = [CellHulls(hullID).imagePixels(idxA); mergeStruct.imagePixels(idxB)];
    
    [r c] = ind2sub(CONSTANTS.imageSize, CellHulls(hullID).indexPixels);
    CellHulls(hullID).centerOfMass = mean([r c]);
    cvIdx = Helper.ConvexHull(c,r);
    if ( isempty(cvIdx) )
        return;
    end
    
    CellHulls(hullID).points = [c(cvIdx) r(cvIdx)];
end

function subtractHulls(hullID, subHullID)
    global CONSTANTS CellHulls
    
    [dump, subIdx] = union(CellHulls(hullID).indexPixels, CellHulls(subHullID).indexPixels);
    CellHulls(hullID).indexPixels = CellHulls(hullID).indexPixels(subIdx);
    CellHulls(hullID).imagePixels = CellHulls(hullID).imagePixels(subIdx);
    
    [r c] = ind2sub(CONSTANTS.imageSize, CellHulls(hullID).indexPixels);
    CellHulls(hullID).centerOfMass = mean([r c]);
    cvIdx = Helper.ConvexHull(c,r);
    if ( isempty(cvIdx) )
        return;
    end
    
    CellHulls(hullID).points = [c(cvIdx) r(cvIdx)];
end

function newHullID = addPointHullEntry(chkPoint, time)
    x = max(round(chkPoint(1)), 1);
    y = max(round(chkPoint(2)), 1);
    
    filename = Helper.GetFullImagePath(time);
    img = Helper.LoadIntensityImage(filename);
    
    newHull = createNewHullStruct(x, y, img(y,x), time);
    newHullID = Hulls.SetHullEntries(0, newHull);
end

function newHullID = addHullEntry(obj, time)
    global CONSTANTS
    
    [r c] = ind2sub(CONSTANTS.imageSize, obj.indPixels);
    
    newHull = createNewHullStruct(c, r, obj.imPixels, time);
    newHullID = Hulls.SetHullEntries(0, newHull);
end

function newHull = createNewHullStruct(x,y, imagePixels, time)
    global CONSTANTS CellHulls
    
    newHull = Helper.MakeEmptyStruct(CellHulls);

    idxPix = sub2ind(CONSTANTS.imageSize, y,x);
    
    newHull.indexPixels = idxPix;
    newHull.imagePixels = imagePixels;
    newHull.centerOfMass = mean([y x], 1);
    newHull.time = time;
    
    chIdx = Helper.ConvexHull(x,y);
    if ( isempty(chIdx) )
        newHull = [];
        return;
    end

    newHull.points = [x(chIdx) y(chIdx)];
end

function objs = partialSegObjs(chkPoint, time)
    filename = Helper.GetFullImagePath(time);
    img = Helper.LoadIntensityImage(filename);

    objs = Segmentation.PartialImageSegment(img, chkPoint, 200, 1.0, time);
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

function dist = getHullDistance(hulls, points)
    global CellHulls
    
    dist = zeros(length(hulls),length(points));
    hullCOM = vertcat(CellHulls(hulls).centerOfMass);
    for i=1:length(hulls)
        dist(i,:) = sum((repmat(hullCOM(i,[2 1]),2,1) - points).^2, 2).';
    end
end

function hull = findHullContainsPoint(point, time, expandRadius)
    global CellHulls HashedCells
    
    if ( ~exist('expandRadius','var') )
        expandRadius = 0;
    end
    
    roundFudge = 0.7072; % sqrt(2)/2
    
    hull = 0;
    
    frameHulls = [HashedCells{time}.hullID];
    
    bMayOverlap = Hulls.RadiusContains(frameHulls, expandRadius+roundFudge, point);
    chkHulls = frameHulls(bMayOverlap);
    if ( isempty(chkHulls) )
        return;
    end
    
    bInHull = false(1,length(chkHulls));
    for i=1:length(chkHulls)
        bInHull(i) = Hulls.ExpandedHullContains(CellHulls(chkHulls(i)).points, expandRadius+roundFudge, point);
    end
    
    chkHulls = chkHulls(bInHull);
    if ( isempty(chkHulls) )
        return;
    end
    
    distSq = sum((vertcat(CellHulls(chkHulls).centerOfMass) - repmat([point(2) point(1)],length(chkHulls),1)).^2, 2);
    [minDistSq minIdx] = min(distSq);

    hull = chkHulls(minIdx);
end
