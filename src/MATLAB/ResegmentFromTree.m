function ResegmentFromTree(rootTracks,preserveTracks)
    global CellHulls HashedCells CellTracks CellFamilies ConnectedDist
    
    if ( ~exist('preserveTracks','var') )
        preserveTracks = [];
    end
    
%     preserveTracks = unique([CellFamilies(preserveTracks).rootTrackID]);
%     rootTracks = unique([CellFamilies(rootTracks).rootTrackID]);
    
    checkTracks = getSubtreeTracks(rootTracks);
    cloneTracks = union(checkTracks,getSubtreeTracks(preserveTracks));
    
    % DON'T change dir to +1, will not work without significant code modification
    dir = -1;
    
    startTime = min([CellTracks(checkTracks).startTime]);
    endTime = max([CellTracks(checkTracks).endTime]);
    
    invalidCheckTracks = [];
    
    for t=endTime:dir:startTime
        % Find tracks which are missing hulls in current frame
        checkTracks = setdiff(checkTracks, invalidCheckTracks);
        cloneTracks = setdiff(cloneTracks, invalidCheckTracks);
        missedTracks = [];
        bInTracks = (t >= [CellTracks(checkTracks).startTime]) & (t <= [CellTracks(checkTracks).endTime]);
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
        [prevHulls bHasPrev] = getHulls(t-dir, cloneTracks);
        
        
        startTracks = cloneTracks([CellTracks(cloneTracks).endTime] == t);
        for i=1:length(startTracks)
            if ( isempty(CellTracks(startTracks(i)).childrenTracks) )
                continue;
            end
            
            childHulls = getHulls(t+1,CellTracks(startTracks(i)).childrenTracks);
            [dump bestCosts] = getBestNextHulls(childHulls, dir);
            [dump minidx] = min(bestCosts);
            prevHulls = [prevHulls childHulls(minidx)];
        end
        
        
        [bestNextHulls bestCosts] = getBestNextHulls(prevHulls, dir);
        
        [splitHulls unMap prevMap] = unique(bestNextHulls);
        
        
        bTryAdd = false(1,length(prevHulls));
        for i=1:length(prevHulls)
            if ( bestNextHulls(i) == 0 )
                bTryAdd(i) = 1;
                continue;
            end
            
            if ( dir > 0 )
                distIdx = find(ConnectedDist{prevHulls(i)}(:,1) == bestNextHulls(i),1,'first');
                dist = ConnectedDist{prevHulls(i)}(distIdx,2);
            else
                distIdx = find(ConnectedDist{bestNextHulls(i)}(:,1) == prevHulls(i),1,'first');
                dist = ConnectedDist{bestNextHulls(i)}(distIdx,2);
            end
            
            if ( dist >= 1.0 )
                bTryAdd(i) = 1;
            end
        end
        
        bAddedHull = false(1,length(prevHulls));
        
        newHulls = [];
        costMatrix = [];
        cfgs = cell(0);
        cfgMap = [];
%         for i=1:length(prevHulls)
%             if ( ~bTryAdd(i) )
%                 continue;
%             end
%             addedHull = tryAddSegmentation(prevHulls(i));
%             
%             if ( addedHull == 0 )
%                 continue;
%             end
% 
%             bAddedHull(i) = 1;
%             newHulls = [newHulls addedHull];
%             
% %             cfgs = [cfgs {[0 prevHulls(i) 0 addedHull]}];
% %             cfgMap = [cfgMap length(cfgs)];
% %             costMatrix = [costMatrix Inf*ones(length(prevHulls),1)];
%         end
        
        
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
                
%                 cfgs = [cfgs {[j 0 splitHulls(i) newSplit]}];
%                 cfgMap = [cfgMap length(cfgs)*ones(1,j)];
%                 costMatrix = [costMatrix Inf*ones(length(prevHulls),j)];
%             end
        end
        
        updateTracking(prevHulls, newHulls, dir);
        
        bInvalidCheckTracks = cellfun(@(x)(isempty(x)),{CellTracks(checkTracks).startTime});
        invalidCheckTracks = checkTracks(bInvalidCheckTracks);
    end
end

function newHullID = tryAddSegmentation(prevHull)
    global CONSTANTS CellHulls CellFeatures HashedCells Figures

    newHullID = [];
    fileName = [CONSTANTS.rootImageFolder CONSTANTS.datasetName '_t' SignificantDigits(Figures.time) '.TIF'];
    [img colrMap] = imread(fileName);
    img = mat2gray(img);
    
    clickPt = [CellHulls(prevHull).centerOfMass(2) CellHulls(prevHull).centerOfMass(1)];
    
    [newObj newFeat] = PartialImageSegment(img, clickPt, 200, 1.0);

    newHull = struct('time', [], 'points', [], 'centerOfMass', [], 'indexPixels', [], 'imagePixels', [], 'deleted', 0, 'userEdited', 1);
    newFeature = struct('darkRatio',{0}, 'haloRatio',{0}, 'igRatio',{0}, 'darkIntRatio',{0}, 'brightInterior',{1}, 'polyPix',{[]}, 'perimPix',{[]}, 'igPix',{[]}, 'haloPix',{[]});
    
    oldTracks = [HashedCells{Figures.time}.trackID];
    
%     if ( ~isempty(newObj) )
%         newObj = makeNonOverlapping(newObj, Figures.time, clickPt);
%     end
    
    if ( isempty(newObj) )
        return;
    else
        newHull.time = Figures.time;
        newHull.points = newObj.points;
        [r c] = ind2sub(CONSTANTS.imageSize, newObj.indPixels);
        newHull.centerOfMass = mean([r c]);
        newHull.indexPixels = newObj.indPixels;
        newHull.imagePixels = newObj.imPixels;
        
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

function updateTracking(prevHulls, newHulls, dir)
    global CellHulls HashedCells Costs GraphEdits
    
    BuildConnectedDistance(newHulls, 1);
    % Add zero costs to cost matrix if necessary
    addCosts = max(max(newHulls)-size(Costs,1),0);
    if (  addCosts > 0 )
        Costs = [Costs zeros(size(Costs,1),addCosts); zeros(addCosts,size(Costs,1)+addCosts)];
        GraphEdits = [GraphEdits zeros(size(GraphEdits,1),addCosts); zeros(addCosts,size(GraphEdits,1)+addCosts)];
    end
    
    % TODO: Remove (possibly update/reinterpret?) graph edits on hulls that are being resegmented
    if ( dir > 0 )
        GraphEdits(prevHulls,:) = 0;
    else
        GraphEdits(:,prevHulls) = 0;
    end
    
    t = CellHulls(prevHulls(1)).time;
    updateHulls = [HashedCells{t}.hullID];
%     if ( dir > 0 )
        UpdateTrackingCosts(t, updateHulls, newHulls);
%     else
%         UpdateTrackingCosts(t, newHulls, prevHulls);
%     end
    
    nextHulls = [HashedCells{t+dir}.hullID];
    if ( dir > 0 )
        [costMatrix bOutTracked bInTracked] = GetCostSubmatrix(prevHulls, nextHulls);
        
        extendHulls = prevHulls(bOutTracked);
        affectedHulls = nextHulls(bInTracked);
    else
        [costMatrix bOutTracked bInTracked] = GetCostSubmatrix(nextHulls, prevHulls);
        costMatrix = (costMatrix');
        
        extendHulls = prevHulls(bInTracked);
        affectedHulls = nextHulls(bOutTracked);
    end
    
    if ( dir > 0 )
        % Not sure how to do this for now
    else
        assignBack(costMatrix, extendHulls, affectedHulls, 0);
    end
    
    % Update Tracking to next frame?
    if ( ((t+dir) > 1) && ((t+dir) < length(HashedCells)) )
        nextHulls = [HashedCells{t+2*dir}.hullID];
%         if ( dir > 0 )
            UpdateTrackingCosts(t+dir, affectedHulls, nextHulls);
%         else
%             UpdateTrackingCosts(t+dir, nextHulls, affectedHulls);
%         end
        
%         [costMatrix bOutTracked bInTracked] = GetCostSubmatrix(newHulls, nextHulls);
% 
%         extendHulls = newHulls(bOutTracked);
%         affectedHulls = nextHulls(bInTracked);
%         ReassignTracks(t+2, costMatrix, extendHulls, affectedHulls, [], 1);
    end
end

function bAssign = assignBack(costMatrix, extendHulls, affectedHulls, bPropForward)
    [minInCosts,bestIncoming] = min(costMatrix,[],1);
    [minOutCosts,bestOutgoing] = min(costMatrix,[],2);
    
    bAssign = false(size(costMatrix));
    
    if ( isempty(costMatrix) )
        return;
    end
    
    bestOutgoing  = bestOutgoing';
    bMatchedCol = false(size(bestIncoming));
    bMatched = (bestIncoming(bestOutgoing) == (1:length(bestOutgoing)));
    bMatchedCol(bestOutgoing(bMatched)) = 1;
    matchedIdx = find(bMatched);
    
    for i=1:length(matchedIdx)
        if ( minOutCosts(matchedIdx(i)) == Inf )
            continue;
        end
        
        nxtAssignHull = affectedHulls(bestOutgoing(matchedIdx(i)));
        fromHull = extendHulls(matchedIdx(i));
        
        AssignEdge(fromHull, nxtAssignHull, bPropForward);
        bAssign(matchedIdx(i), bestOutgoing(matchedIdx(i))) = 1;
    end
end

function [wantHulls wantCosts] = getBestNextHulls(hulls, dir)
    global CellHulls
    
    wantHulls = zeros(1,length(hulls));
    wantCosts = Inf*ones(1,length(hulls));
    
    if ( dir > 0 )
        checkHulls = hulls;
        nextHulls = 1:length(CellHulls);
        
        [costMatrix,bFrom,bToHulls] = GetCostSubmatrix(checkHulls,nextHulls);
        toHulls = find(bToHulls);
        
        [minOut bestOutIdx] = min(costMatrix,[],2);
        wantHulls(bFrom) = toHulls(bestOutIdx);
        wantCosts(bFrom) = minOut;
    else
        checkHulls = 1:length(CellHulls);
        nextHulls = hulls;
        
        [costMatrix,bFrom,bToHulls] = GetCostSubmatrix(checkHulls,nextHulls);
        fromHulls = find(bFrom);
        
        [minIn bestInIdx] = min(costMatrix,[],1);
        wantHulls(bToHulls) = fromHulls(bestInIdx);
        wantCosts(bToHulls) = minIn;
    end
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