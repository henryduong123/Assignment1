function ResegmentFromTree(rootTracks,preserveTracks)
    global CellHulls HashedCells CellTracks CellFamilies ConnectedDist
    
    if ( ~exist('preserveTracks','var') )
        preserveTracks = [];
    end
    
    checkTracks = getSubtreeTracks(rootTracks);
    preserveTracks = union(checkTracks,getSubtreeTracks(preserveTracks));
    
    bEmptyPreserveTracks = cellfun(@(x)(isempty(x)),{CellTracks(preserveTracks).startTime});
    if ( any(bEmptyPreserveTracks) )
        error('Attempt to preserve empty track');
    end
    
    invalidPreserveTracks = [];
    
    UI.Progressbar(0);
    for t=2:length(HashedCells)
        % Find tracks which are missing hulls in current frame
        checkTracks = setdiff(checkTracks, invalidPreserveTracks);
        preserveTracks = setdiff(preserveTracks, invalidPreserveTracks);
        
        prevHulls = getHulls(t-1, preserveTracks);
        
        if ( isempty(prevHulls) )
            continue;
        end
        
        % TODO: This needs to deal with mitosis events, add in hulls for
        % all secondary mitosis edges.
        bestNextHulls = getBestNextHulls(prevHulls);
        splitHulls = unique([bestNextHulls{:}]);
        
        bTryAdd = false(1,length(prevHulls));
        for i=1:length(prevHulls)
            if ( isempty(bestNextHulls{i}) )
                bTryAdd(i) = 1;
                continue;
            end
            
            dist = Tracker.GetConnectedDistance(prevHulls(i),bestNextHulls{i}(1));
            if ( dist >= 1.0 )
                bTryAdd(i) = 1;
            end
        end
        
        bAddedHull = false(1,length(prevHulls));
        
        newHulls = [];
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
        end
        
        maxSplit = zeros(1,length(splitHulls));
        for i=1:length(splitHulls)
            bWantSplit = cellfun(@(x)(any(x==splitHulls(i))), bestNextHulls) & (~bAddedHull);
            maxSplit(i) = nnz(bWantSplit);
        end
        
        for i=1:length(splitHulls)
            j = maxSplit(i);
            if ( (splitHulls(i) == 0) || (j <= 0) )
                continue;
            end
            
            newSplit = trySplitSegmentation(splitHulls(i),j);
            newHulls = [newHulls newSplit];
        end
        
        updateTracking(prevHulls, newHulls, preserveTracks);
        
        bInvalidPreserveTracks = cellfun(@(x)(isempty(x)),{CellTracks(preserveTracks).startTime});
        invalidPreserveTracks = preserveTracks(bInvalidPreserveTracks);
        
        UI.Progressbar(abs(t)/abs(length(HashedCells)));
    end
    UI.Progressbar(1);
end

function [edgeList edgeTimes] = getTrackEdges(tStart, tracks)
    global CellTracks CellHulls
    
    edgeList = [];
    edgeTimes = [];
    [startHulls bHasStart] = getHulls(tStart, tracks);
    
    inTracks = tracks(bHasStart);
    for i=1:length(inTracks)
        nextHulls = Helper.GetNearestTrackHull(inTracks(i), tStart+1, 1);
        if ( nextHulls == 0 )
            if ( isempty(CellTracks(inTracks(i)).childrenTracks) )
                continue;
            end
            
            nextHulls = zeros(1,length(CellTracks(inTracks(i)).childrenTracks));
            for j=1:length(CellTracks(inTracks(i)).childrenTracks)
                nextHulls(j) = Helper.GetNearestTrackHulls(CellTracks(inTracks(i)).childrenTracks(j), tStart+1, -1);
            end
            if ( any(nextHulls == 0) )
                continue;
            end
        end
        
        for j=1:length(nextHulls)
            edgeList = [edgeList; startHulls(i) nextHulls(j)];
            edgeTimes = [edgeTimes; CellHulls(startHulls(i)).time CellHulls(nextHulls(j)).time];
        end
    end
end

function newHullID = tryAddSegmentation(prevHull)
    global CONSTANTS CellHulls

    newHullID = [];
    
    time = CellHulls(prevHull).time + 1;
    
    fileName = Helper.GetFullImagePath(time);
    img = Helper.LoadIntensityImage(fileName);
    
    guessPoint = [CellHulls(prevHull).centerOfMass(2) CellHulls(prevHull).centerOfMass(1)];
    
    [newObj newFeat] = Segmentation.PartialImageSegment(img, guessPoint, 200, 1.0);
    
    if ( isempty(newObj) )
        return;
    end
    
    newHull = struct('time', [], 'points', [], 'centerOfMass', [], 'indexPixels', [], 'imagePixels', [], 'deleted', 0, 'userEdited', 1);
    
    newHull.time = time;
    newHull.points = newObj.points;
    
    [r c] = ind2sub(CONSTANTS.imageSize, newObj.indPixels);
    newHull.centerOfMass = mean([r c]);
    newHull.indexPixels = newObj.indPixels;
    newHull.imagePixels = newObj.imPixels;
    
    newHullID = Hulls.SetHullEntries(0, newHull);
end

function newHullIDs = trySplitSegmentation(hullID, k)
    global CellHulls

    newHullIDs = [];
    
    if ( k == 1 )
        newHullIDs = hullID;
        return;
    end
    
    
    [newHulls newFeats] = Segmentation.ResegmentHull(CellHulls(hullID), k);
    if ( isempty(newHulls) )
        return;
    end
    
    % TODO: fixup incoming graphedits

    setHullIDs = zeros(1,length(newHulls));
    setHullIDs(1) = hullID;
    % Just arbitrarily assign clone's hull for now
    newHullIDs = Hulls.SetHullEntries(setHullIDs, newHulls);
end

function updateTracking(prevHulls, newHulls, preserveTracks)
    global CellHulls HashedCells Costs GraphEdits
    
    if ( isempty(newHulls) )
        return;
    end
    
    t = CellHulls(prevHulls(1)).time;
    updateHulls = [HashedCells{t}.hullID];

    % TODO: keep around long term graphedits for prevHulls?
    forwardEdits = find(any((GraphEdits(prevHulls,:) ~= 0),1));
    bLongEdits = ([CellHulls(forwardEdits).time] > (t+1));
    Tracker.GraphEditsResetHulls(prevHulls(bLongEdits), 1, 0);
    
    Tracker.UpdateTrackingCosts(t, updateHulls, newHulls);
    
    nextHulls = [HashedCells{t+1}.hullID];
    [costMatrix bOutTracked bInTracked] = Tracker.GetCostSubmatrix(prevHulls, nextHulls);
    fromHulls = prevHulls(bOutTracked);
    toHulls = nextHulls(bInTracked);

    % TODO: Tree-preserving assignment code
    reassignPreserveEdges(costMatrix, fromHulls, toHulls, preserveTracks);
    
    %TODO: go ahead and update tracking, but no need to reassign since we now
    % hit every frame that has valid tracks.
    
    % Update Tracking to next frame?
    if ( (t+1) < length(HashedCells) )
        nextHulls = [HashedCells{t+2}.hullID];
        if ( isempty(nextHulls) || isempty(toHulls) )
            return;
        end
        
        Tracker.UpdateTrackingCosts(t+1, toHulls, nextHulls);
    end
end

function [bAssign emptyTracks] = reassignPreserveEdges(costMatrix, fromHulls, toHulls, preserveTracks)
    global CellHulls CellTracks Costs
    
    [minInCosts,bestIncoming] = min(costMatrix,[],1);
    [minOutCosts,bestOutgoing] = min(costMatrix,[],2);
    
    bAssign = false(size(costMatrix));
    emptyTracks = [];
    
    if ( isempty(costMatrix) )
        return;
    end
    
    bestOutgoing  = bestOutgoing';
    bMatched = (bestIncoming(bestOutgoing) == (1:length(bestOutgoing)));
    matchedIdx = find(bMatched);
    
    preserveEdges = getPreserveEdges(fromHulls(matchedIdx), preserveTracks);
    [chkHulls oldAssign] = getAssignedTracks(preserveEdges);
    
    edges = [(fromHulls(matchedIdx)') (toHulls(bestOutgoing(matchedIdx))')];
    
    % Ignore edges that are assigned the same as previously
    bSame = ismember(edges, preserveEdges, 'rows');
    edges = edges(~bSame,:);
    
    if ( isempty(edges) )
        return;
    end
    
    possibleTimeChange = Hulls.GetTrackID(edges(:,2));
    
    droppedTracks = [];
    for i=1:size(edges,1)
        latestDropped = Tracks.RemoveHullFromTrack(edges(i,2));
        
        if ( length(latestDropped) > 2 )
            % TODO: deal with this
            error('Dropped a single-frame track with parent and children');
        end
        
        droppedTracks = [droppedTracks latestDropped];
    end
    
    % Assign edges (fixup tree breaks as we go)
    for i=1:size(edges,1)
        assignIdx = find(chkHulls == edges(i,1));
        if ( isempty(assignIdx) )
            assignTrack = Hulls.GetTrackID(edges(i,1));
        else
            assignTrack = oldAssign{assignIdx};
        end
        
        t = CellHulls(edges(i,2)).time;
        assignTrack = assignTrack(1);
        curHullID = Tracks.GetHullID(t, assignTrack);
        
        fixupTracks = [];
        if ( curHullID > 0 )
            fixupTracks = Tracks.RemoveHullFromTrack(curHullID);
            Families.NewCellFamily(curHullID);
        end
        
        errDropped = Tracks.AddHullToTrack(edges(i,2), assignTrack, []);
        if ( ~isempty(errDropped) )
            error('Added hull past mitosis causing tracks to drop from tree');
        end
        
        parentTrack = Hulls.GetTrackID(edges(i,1));
        if ( length(fixupTracks) > 2 )
            bSibling = (fixupTracks ~= assignTrack) & ([CellTracks(fixupTracks).startTime] == CellHulls(edges(i,2)).time);
            siblingTrack = fixupTracks(bSibling);
            
            if ( isempty(siblingTrack) )
                error('Single hull removal unfixable, cannot find sibling');
            end
            
            Families.ReconnectParentWithChildren(parentTrack,[assignTrack siblingTrack]);
            parentTrack = assignTrack;
        end
        
        if ( ~isempty(fixupTracks) )
            Families.ReconnectParentWithChildren(parentTrack,fixupTracks);
        end
    end
    
    % Fix up and reconnect the preserve tracks that were dropped before
    % reassignment
    bPreserveDropped = ismember(droppedTracks, preserveTracks);
    droppedTracks = droppedTracks(bPreserveDropped);
    
    if ( isempty(droppedTracks) )
        return;
    end
    
    % Find tracks that have lost their first hull and been dropped
    bLostHull = ([CellTracks(possibleTimeChange).startTime] > [CellHulls(edges(:,2)).time]);
    bNeedsHull = bLostHull & ismember(possibleTimeChange,droppedTracks);
    
    % Find the closest previous hull to add back to beginning of shortened
    % track
    needHullTracks = possibleTimeChange(bNeedsHull);
    for i=1:length(needHullTracks)
        nextHull = CellTracks(needHullTracks).hulls(1);
        
        prevHulls = find(Costs(:,nextHull) > 0);
        bNotPreserved = ~ismember(Hulls.GetTrackID(prevHulls), preserveTracks);
        prevHulls = prevHulls(bNotPreserved);
        
        [bestCost bestIdx] = min(Costs(prevHulls,nextHull));
        if ( isempty(bestIdx) )
            error('No hulls exist in previous frame to extend track back correctly');
            continue;
        end
        
        bestHull = prevHulls(bestIdx);
        Tracks.RemoveHullFromTrack(bestHull);
        Tracks.AddHullToTrack(bestHull, needHullTracks(i),[]);
    end
    
    leafHulls = [];
    for i=1:length(preserveTracks)
        if ( isempty(CellTracks(preserveTracks(i)).startTime) )
            continue;
        end
        
        trackEnd = CellTracks(preserveTracks(i)).endTime;
        if ( ~ismember(trackEnd,[t-1 t]) )
            continue;
        end
        
        leafHulls = [leafHulls Tracks.GetHullID(trackEnd, preserveTracks(i))];
    end
    
    startTrackHulls = [];
    for i=1:length(droppedTracks)
        if ( isempty(CellTracks(droppedTracks(i)).startTime) )
            continue;
        end
        
        trackStart = CellTracks(droppedTracks(i)).startTime;
        startTrackHulls = [startTrackHulls Tracks.GetHullID(trackStart, droppedTracks(i))];
    end
    
    [costMatrix bLeaf bNext] = Tracker.GetCostSubmatrix(leafHulls, startTrackHulls);
    leafHulls = leafHulls(bLeaf);
    startTrackHulls = startTrackHulls(bNext);
    
    [minCost minIdx] = min(costMatrix(:));
    [minR minC] = ind2sub(size(costMatrix), minIdx);
    
    edgeAssign = cell(1,length(leafHulls));
    while ( ~isinf(minCost) )
        bCheckTime = (CellHulls(leafHulls(minR)).time == CellHulls(startTrackHulls(minC)).time - 1);
        if ( ~bCheckTime )
            costMatrix(minR,minC) = Inf;
        elseif ( length(edgeAssign{minR}) < 2 )
            edgeAssign{minR} = [edgeAssign{minR} minC];
            costMatrix(:,minC) = Inf;

            if ( length(edgeAssign{minR}) == 2)
                costMatrix(minR,:) = Inf;
            end
        else
            costMatrix(minR,:) = Inf;
        end
        
        [minCost minIdx] = min(costMatrix(:));
        [minR minC] = ind2sub(size(costMatrix), minIdx);
    end
    
    for i=1:length(edgeAssign)
        if ( isempty(edgeAssign{i}) )
            continue;
        end
        
        if ( length(edgeAssign{i}) == 1 )
            parentTrack = Hulls.GetTrackID(leafHulls(i));
            childTrack = Hulls.GetTrackID(startTrackHulls(edgeAssign{i}));
            
            Tracks.ChangeTrackID(childTrack, parentTrack);
        elseif ( length(edgeAssign{i}) == 2 )
            parentTrack = Hulls.GetTrackID(leafHulls(i));
            childTracks = Hulls.GetTrackID(startTrackHulls(edgeAssign{i}));
            
            Families.ReconnectParentWithChildren(parentTrack, childTracks);
        end
    end
    
    for i=1:length(droppedTracks)
        if ( isempty(CellTracks(droppedTracks(i)).startTime) || isempty(CellTracks(droppedTracks(i)).parentTrack) )
            emptyTracks = [emptyTracks droppedTracks(i)];
        end
    end
    
    % TODO: Handle this
    if ( ~isempty(emptyTracks) )
        error('Dropped preserve tracks');
    end
end

function [hulls tracks] = getAssignedTracks(edges)
    hulls = unique(edges(:,1));
    
    tracks = cell(length(hulls),1);
    for i=1:length(hulls)
        bChkIdx = (edges(:,1)==hulls(i));
        tracks{i} = [tracks{i} Hulls.GetTrackID(edges(bChkIdx,2))];
    end
end

function edgesList = getPreserveEdges(fromHulls, preserveTracks)
    global CellHulls CellTracks
    
    edgesList = [];
    edgesTimes = [];
    
    inTracks = Hulls.GetTrackID(fromHulls);
    bPreserve = ismember(inTracks, preserveTracks);
    
    inTracks = inTracks(bPreserve);
    fromHulls = fromHulls(bPreserve);
    for i=1:length(fromHulls)
        t = CellHulls(fromHulls(i)).time;
        nextHulls = Helper.GetNearestTrackHull(inTracks(i), t+1, 1);
        if ( nextHulls == 0 )
            if ( isempty(CellTracks(inTracks(i)).childrenTracks) )
                continue;
            end
            
            nextHulls = zeros(1,length(CellTracks(inTracks(i)).childrenTracks));
            for j=1:length(CellTracks(inTracks(i)).childrenTracks)
                nextHulls(j) = Helper.GetNearestTrackHull(CellTracks(inTracks(i)).childrenTracks(j), t+1, -1);
            end
            if ( any(nextHulls == 0) )
                continue;
            end
        end
        
        for j=1:length(nextHulls)
            edgesList = [edgesList; fromHulls(i) nextHulls(j)];
            edgesTimes = [edgesTimes; CellHulls(fromHulls(i)).time CellHulls(nextHulls(j)).time];
        end
    end
end

function [wantHulls wantCosts] = getBestNextHulls(hulls)
    global CellHulls CellTracks HashedCells
    
    wantHulls = cell(1,length(hulls));
    wantCosts = Inf*ones(1,length(hulls));
    
    t = CellHulls(hulls(1)).time;
    if ( t >= length(HashedCells) )
        return;
    end

    checkHulls = hulls;
    nextHulls = 1:length(CellHulls);

    [costMatrix,bFrom,bToHulls] = Tracker.GetCostSubmatrix(checkHulls,nextHulls);
    toHulls = find(bToHulls);
    
    idx = find(bFrom);
    fromHulls = checkHulls(bFrom);
    [minOut bestOutIdx] = min(costMatrix,[],2);
    for i=1:length(idx)
        wantHulls{idx(i)} = toHulls(bestOutIdx(i));
    end
	wantCosts(bFrom) = minOut;
    
    fromTracks = Hulls.GetTrackID(fromHulls);
    for i=1:length(fromTracks)
        if ( CellTracks(fromTracks(i)).endTime == t )
            continue;
        end
        
        if ( isempty(CellTracks(fromTracks(i)).childrenTracks) )
            continue;
        end
        
        nextHull = CellTracks(CellTracks(fromTracks(i)).childrenTracks(2)).hulls(1);
        wantHulls{i} = [wantHulls{i} nextHull];
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
        hullID = Tracks.GetHullID(t,tracks(i));
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
