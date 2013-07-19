
function parentHull = FindParentHull(childHulls, linePoints, time, forceParents)
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
    mitosisCVIdx = 1:size(mitosisPoints,1);
    try
        mitosisCVIdx = convhull(mitosisPoints(:,1), mitosisPoints(:,2));
    catch err
    end
    
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
    parentHull = addParentHull(midpoint, time, mitosisPoints);
end

function parentHull = addParentHull(midpoint, time, mitosisPoints)
    global CONSTANTS
    
    parentHull = [];
    
    filename = Helper.GetFullImagePath(time);
    img = Helper.LoadIntensityImage(filename);
    
    objs = Segmentation.PartialImageSegment(img, midpoint, 200, 1.0);
    
    pointCounts = zeros(1,length(objs));
    for i=1:length(objs)
        [r c] = ind2sub(CONSTANTS.imageSize, objs(i).indPixels);
        bContainsPoints = inpolygon(c,r, mitosisPoints(:,1), mitosisPoints(:,2));
        pointCounts(i) = nnz(bContainsPoints);
    end
    
    [maxPoints maxIdx] = max(pointCounts);
    if ( maxPoints > 0 )
        parentHull = addHullEntry(objs(maxIdx), time);
        Tracker.TrackAddedHulls(parentHull, midpoint);
        return;
    end
    
    parentHull = addPointHullEntry(midpoint, time);
    Tracker.TrackAddedHulls(parentHull, midpoint);
end

function newHullID = addPointHullEntry(chkPoint, time)
    x = round(chkPoint(1));
    y = round(chkPoint(2));
    
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
    
    if ( length(x) > 1 )
        try
            chIdx = convhull(x, y);
        catch excp
            newHull = [];
            return;
        end
    else
        chIdx = 1;
    end

    newHull.points = [x(chIdx) y(chIdx)];
end
