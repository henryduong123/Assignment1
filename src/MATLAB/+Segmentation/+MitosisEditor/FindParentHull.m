
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
    
    chkMitosisCVIdx = Helper.ConvexHull(mitosisPoints(:,1), mitosisPoints(:,2));
    if ( ~isempty(chkMitosisCVIdx) )
        mitosisCVIdx = chkMitosisCVIdx;
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
    
    imSet = Helper.LoadIntensityImageSet(time);

    typeParams = Load.GetCellTypeParameters(CONSTANTS.cellType);
    segFunc = typeParams.resegRoutines(1).func;
    paramData = typeParams.resegRoutines(1).params;
    
    segParams = cell(1,length(paramData));
    for i=1:length(paramData)
        if ( isempty(paramData(i).range) )
            segParams{i} = paramData(i).default;
        else
            segParams{i} = paramData(i).range(1);
        end
    end
    
    hulls = Segmentation.PartialImageSegment(imSet, midpoint, 200, segFunc, segParams);
    
    pointCounts = zeros(1,length(hulls));
    for i=1:length(hulls)
        [r c] = ind2sub(CONSTANTS.imageSize, hulls(i).indexPixels);
        bContainsPoints = inpolygon(c,r, mitosisPoints(:,1), mitosisPoints(:,2));
        pointCounts(i) = nnz(bContainsPoints);
    end
    
    [maxPoints maxIdx] = max(pointCounts);
    if ( maxPoints > 0 )
        parentHull = addHullEntry(hulls(maxIdx), time);
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
    
    newHull = createNewHullStruct(x, y, time);
    newHullID = Hulls.SetCellHullEntries(0, newHull);
end

function newHullID = addHullEntry(hull, time)
    global CONSTANTS
    
    [r c] = ind2sub(CONSTANTS.imageSize, hull.indexPixels);
    
    newHull = createNewHullStruct(c, r, time);
    newHullID = Hulls.SetCellHullEntries(0, newHull);
end

function newHull = createNewHullStruct(x,y, time)
    global CONSTANTS CellHulls
    
    newHull = Helper.MakeEmptyStruct(CellHulls);

    idxPix = sub2ind(CONSTANTS.imageSize, y,x);
    
    newHull.indexPixels = idxPix;
    newHull.centerOfMass = mean([y x], 1);
    newHull.time = time;
    
    chIdx = Helper.ConvexHull(x,y);
    if ( isempty(chIdx) )
        newHull = [];
        return;
    end

    newHull.points = [x(chIdx) y(chIdx)];
end
