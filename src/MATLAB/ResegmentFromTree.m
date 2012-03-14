function ResegmentFromTree(rootTracks,preserveTracks)
    global CellHulls HashedCells CellTracks CellFamilies ConnectedDist
    
    if ( ~exist('preserveTracks','var') )
        preserveTracks = [];
    end
    
%     preserveTracks = unique([CellFamilies(preserveTracks).rootTrackID]);
%     rootTracks = unique([CellFamilies(rootTracks).rootTrackID]);
    
    checkTracks = getSubtreeTracks(rootTracks);
    cloneTracks = union(checkTracks,getSubtreeTracks(preserveTracks));
    
    startTime = min([CellTracks(checkTracks).startTime]);
    endTime = max([CellTracks(checkTracks).endTime]);
    
    for t=startTime:endTime
        % Find tracks which are missing hulls in current frame
        missedTracks = [];
        bInTracks = (t >= [CellTracks(checkTracks).startTime]) & (t < [CellTracks(checkTracks).endTime]);
        inTracks = checkTracks(bInTracks);
        for i=1:length(inTracks)
            hash = t - CellTracks(inTracks(i)).startTime + 1;
            if ( CellTracks(inTracks(i)).hulls(hash) > 0 )
                continue;
            end
            
            missedTracks = union(missedTracks, inTracks(i));
        end
        
        if ( isempty(missedTracks) )
            continue;
        end
        
%         [prevHulls bHasPrev] = getHulls(t-1, missedTracks);
%         prevTracks = missedTracks(bHasPrev);
        [prevHulls bHasPrev] = getHulls(t-1, cloneTracks);
        prevTracks = cloneTracks(bHasPrev);
        
        [bestNextHulls bestCosts] = getBestNextHulls(prevHulls);
        
        [splitHulls unMap prevMap] = unique(bestNextHulls);
        
%         maxSplit = zeros(1,length(splitHulls));
        bTryAdd = false(1,length(prevHulls));
        
        for i=1:length(prevHulls)
            if ( bestNextHulls(i) == 0 )
                bTryAdd(i) = 1;
                continue;
            end
            
            distIdx = find(ConnectedDist{prevHulls(i)}(:,1) == bestNextHulls(i),1,'first');
            dist = ConnectedDist{prevHulls(i)}(distIdx,2);
            if ( dist >= 1.0 )
                bTryAdd(i) = 1;
            end
            
%             maxSplit(prevMap(i)) = maxSplit(prevMap(i)) + 1;
        end
        
        bAddedHull = false(1,length(prevHulls));
        
        newHulls = [];
        costMatrix = [];
        cfgs = cell(0);
        cfgMap = [];
        for i=1:length(prevHulls)
            if ( ~bTryAdd(i) )
                continue;
            end
            addedHull = tryAddSegmentation(prevHulls(i));
            
            if ( addedHull == 0 )
                continue;
            end

            bAddedHull(i) = 1;
            newHulls = [newHulls addedHull];
            
            cfgs = [cfgs {[0 prevHulls(i) 0 addedHull]}];
            cfgMap = [cfgMap length(cfgs)];
            costMatrix = [costMatrix Inf*ones(length(prevHulls),1)];
        end
        
        maxSplit = zeros(1,length(splitHulls));
        for i=1:length(splitHulls)
            bWantSplit = (bestNextHulls == splitHulls(i)) & (~bAddedHull);
            maxSplit(i) = nnz(bWantSplit);
        end
        
        for i=1:length(splitHulls)
%             for j=1:length(maxSplit(i))
                j = maxSplit(i);
                if ( j <= 0 )
                    continue;
                end
                newSplit = trySplitSegmentation(splitHulls(i),j);
                
                newHulls = [newHulls newSplit];
                
                cfgs = [cfgs {[j 0 splitHulls(i) newSplit]}];
                cfgMap = [cfgMap length(cfgs)*ones(1,j)];
                costMatrix = [costMatrix Inf*ones(length(prevHulls),j)];
%             end
        end
        
        updateTracking(prevHulls, newHulls);
    end
end

function newHullID = tryAddSegmentation(prevHull)
    global CONSTANTS CellHulls CellFeatures HashedCells Figures

    newHullID = [];
    fileName = [CONSTANTS.rootImageFolder CONSTANTS.datasetName '_t' SignificantDigits(Figures.time) '.TIF'];
    [img colrMap] = imread(fileName);
    img = mat2gray(img);
    
    clickPt = CellHulls(prevHull).centerOfMass;
    
    [newObj newFeat] = PartialImageSegment(img, clickPt, 200, 1.0);

    newHull = struct('time', [], 'points', [], 'centerOfMass', [], 'indexPixels', [], 'imagePixels', [], 'deleted', 0, 'userEdited', 1);
    newFeature = struct('darkRatio',{0}, 'haloRatio',{0}, 'igRatio',{0}, 'darkIntRatio',{0}, 'brightInterior',{1}, 'polyPix',{[]}, 'perimPix',{[]}, 'igPix',{[]}, 'haloPix',{[]});
    
    oldTracks = [HashedCells{Figures.time}.trackID];
    
    if ( ~isempty(newObj) )
        newObj = makeNonOverlapping(newObj, Figures.time, clickPt);
    end
    
    if ( isempty(newObj) )
%         % Add a point hull since we couldn't find a segmentation containing the click
%         newHull.time = Figures.time;
%         newHull.points = round(clickPt);
%         newHull.centerOfMass =  [clickPt(2) clickPt(1)];
%         newHull.indexPixels = sub2ind(size(img), newHull.points(2), newHull.points(1));
%         newHull.imagePixels = img(newHull.indexPixels);
%         
%         newFeature.polyPix = newHull.indexPixels;
        return;
    else
        newHull.time = Figures.time;
        newHull.points = newObj.points;
        newHull.centerOfMass = newObj.centerOfMass;
        newHull.indexPixels = newObj.indexPixels;
        newHull.imagePixels = newObj.imagePixels;
        
        newFeature = newFeat;
    end

    newHullID = length(CellHulls)+1;
    CellHulls(newHullID) = newHull;
    
    % Set feature if valid
    if ( ~isempty(CellFeatures) )
        CellFeatures(newHullID) = newFeature;
    end
    
    newFamilyIDs = NewCellFamily(newHullID, newHull.time);
end

function newHullIDs = trySplitSegmentation(hullID, k)
    global CellHulls CellFeatures

    newHullIDs = [];
    
    oldHull = CellHulls(hullID);
    oldFeat = [];
    
    if ( k == 1 )
        newHullIDs = hullID;
        return;
    end
    
    if ( ~isempty(CellFeatures) )
        oldFeat = CellFeatures(hullID);
    end
    
% 	[newHulls newFeats] = WatershedSplitCell(CellHulls(hullID), oldFeat, k);
%     if ( isempty(newHulls) )
        [newHulls newFeats] = ResegmentHull(CellHulls(hullID), oldFeat, k);
        if ( isempty(newHulls) )
            return;
        end
%     end

    % Just arbitrarily assign clone's hull for now
    CellHulls(hullID) = newHulls(1);
    newHullIDs = hullID;

    % Other hulls are just added off the clone
    newFamilyIDs = [];
    for i=2:length(newHulls)
        CellHulls(end+1) = newHulls(i);
        newFamilyIDs = [newFamilyIDs NewCellFamily(length(CellHulls), newHulls(i).time)];
        newHullIDs = [newHullIDs length(CellHulls)];
    end
    
    if ( ~isempty(CellFeatures) )
        for i=1:length(newHullIDs)
            CellFeatures(newHullIDs(i)) = newFeats(i);
        end
    end
end

function updateTracking(prevHulls, newHulls)
    global CellHulls HashedCells Costs GraphEdits
    
    BuildConnectedDistance(newHulls, 1);
    % Add zero costs to cost matrix if necessary
    addCosts = max(max(newHulls)-size(Costs,1),0);
    if (  addCosts > 0 )
        Costs = [Costs zeros(size(Costs,1),addCosts); zeros(addCosts,size(Costs,1)+addCosts)];
        GraphEdits = [GraphEdits zeros(size(GraphEdits,1),addCosts); zeros(addCosts,size(GraphEdits,1)+addCosts)];
    end
    
    % TODO: Remove (possibly update/reinterpret?) graph edits on hulls that are being resegmented
    GraphEdits(prevHulls,:) = 0;
    
    t = CellHulls(prevHulls(1)).time;
    UpdateTrackingCosts(t, prevHulls, newHulls);
    
    nextHulls = [HashedCells{t+1}.hullID];
    [costMatrix bOutTracked bInTracked] = GetCostSubmatrix(prevHulls, nextHulls);
    
    extendHulls = prevHulls(bOutTracked);
    affectedHulls = nextHulls(bInTracked);
    ReassignTracks(t+1, costMatrix, extendHulls, affectedHulls, []);
    
    % Update Tracking to next frame?
    if ( (t+1) < length(HashedCells) )
        nextHulls = [HashedCells{t+2}.hullID];
        UpdateTrackingCosts(t+1, affectedHulls, nextHulls);
        
%         [costMatrix bOutTracked bInTracked] = GetCostSubmatrix(newHulls, nextHulls);
% 
%         extendHulls = newHulls(bOutTracked);
%         affectedHulls = nextHulls(bInTracked);
%         ReassignTracks(t+2, costMatrix, extendHulls, affectedHulls, [], 1);
    end
end

function [wantHulls wantCosts] = getBestNextHulls(hulls)
    global CellHulls
    
    wantHulls = zeros(1,length(hulls));
    wantCosts = Inf*ones(1,length(hulls));
    
    [costMatrix,bFrom,bToHulls] = GetCostSubmatrix(hulls,1:length(CellHulls));
    toHulls = find(bToHulls);
    [minOut bestIdx] = min(costMatrix,[],2);
    
    wantHulls(bFrom) = toHulls(bestIdx);
    wantCosts(bFrom) = minOut;
end

function [hulls bHasHull] = getHulls(t, tracks)
    global HashedCells
    
    hulls = [];
    bHasHull = false(1,length(tracks));
    
    if ( t <= 0 || t > length(HashedCells) )
        return;
    end
    
    for i=1:length(tracks)
        hullID = GetHullID(t,tracks(i));
        if ( hullID == 0 )
            continue;
        end
        
        hulls = [hulls hullID];
        bHasHull(i) = 1;
    end
end

function childTracks = getSubtreeTracks(rootTracks)
    global CellTracks
    
    childTracks = rootTracks;
    while ( any(~isempty([CellTracks(childTracks).childrenTracks])) )
        newTracks = setdiff([CellTracks(childTracks).childrenTracks], childTracks);
        if ( isempty(newTracks) )
            return;
        end
        
        childTracks = union(childTracks, newTracks);
    end
end