function segEdits = ResegmentFromTree(rootTracks,preserveTracks)
    global CellHulls HashedCells CellTracks CellFamilies ConnectedDist
    
    global Figures
    
    if ( ~exist('preserveTracks','var') )
        preserveTracks = [];
    end
    
    checkTracks = getSubtreeTracks(rootTracks);
    preserveTracks = union(checkTracks,getSubtreeTracks(preserveTracks));
    
    bEmptyPreserveTracks = cellfun(@(x)(isempty(x)),{CellTracks(preserveTracks).startTime});
    if ( any(bEmptyPreserveTracks) )
        error('Attempt to preserve empty track');
    end
    
    costMatrix = Tracker.GetCostMatrix();
    mexDijkstra('initGraph', costMatrix);
    
    invalidPreserveTracks = [];
    
    minAddDist = 2.0;
    
    famID = CellTracks(rootTracks(1)).familyID;
    saveMovieFrame(1, famID, 'C:\Users\mwinter\Documents\Figures\isbi_movie\edited_reseg');
    
    segEdits = {};
    
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
            if ( dist >= minAddDist )
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
            
            segEdits = [segEdits;{t+1 [CellHulls(prevHulls(i)).centerOfMass(2) CellHulls(prevHulls(i)).centerOfMass(1)] '+'}];

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
            
            if ( length(newSplit) > 1 )
                segEdits = [segEdits;{t+1 [CellHulls(splitHulls(i)).centerOfMass(2) CellHulls(splitHulls(i)).centerOfMass(1)] 'x'}];
            end
        end
        
        newPreserveTracks = updateTracking(prevHulls, newHulls, preserveTracks);
        preserveTracks = [preserveTracks newPreserveTracks];
        [dump sortedIdx] = unique(preserveTracks, 'first');
        sortedIdx = sort(sortedIdx);
        preserveTracks = preserveTracks(sortedIdx);
        
        bInvalidPreserveTracks = cellfun(@(x)(isempty(x)),{CellTracks(preserveTracks).startTime});
        invalidPreserveTracks = preserveTracks(bInvalidPreserveTracks);
        
        % DEBUG
        Figures.time = t;
        validPreserveTracks = preserveTracks(~bInvalidPreserveTracks);
        famID = CellTracks(validPreserveTracks(1)).familyID;
        
        % Make Movie code
        saveMovieFrame(t, famID, 'C:\Users\mwinter\Documents\Figures\isbi_movie\edited_reseg');
        
        UI.Progressbar(abs(t)/abs(length(HashedCells)));
    end
    UI.Progressbar(1);
end

function saveMovieFrame(t, famID, outdir)
    global Figures CONSTANTS
    
    UI.DrawTree(famID);
    UI.TimeChange(t);
    drawnow();
    
    figure(Figures.cells.handle)
    X = getframe();
    imwrite(X.cdata, fullfile(outdir,['cells_' CONSTANTS.datasetName num2str(t, '%04d') '.tif']), 'tiff');

    figure(Figures.tree.handle)
    X = getframe();
    imwrite(X.cdata, fullfile(outdir,['tree_' CONSTANTS.datasetName num2str(t, '%04d') '.tif']), 'tiff');
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
    
    [newObj newFeat] = Segmentation.PartialImageSegment(img, guessPoint, 200, 1.0, CellHulls(prevHull).indexPixels);
    
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

function updateDijkstraGraph(updateHulls, nextHulls)
    if ( isempty(updateHulls) || isempty(nextHulls) )
        return;
    end
    
    [costMatrix bOutTracked bInTracked] = Tracker.GetCostSubmatrix(updateHulls, nextHulls);
    fromHulls = updateHulls(bOutTracked);
    toHulls = nextHulls(bInTracked);
    
    mexDijkstra('updateGraph', costMatrix, fromHulls, toHulls);
end

function newPreserveTracks = updateTracking(prevHulls, newHulls, preserveTracks)
    global CellHulls HashedCells Costs GraphEdits
    
    if ( isempty(newHulls) )
        return;
    end
    
    t = CellHulls(prevHulls(1)).time;
    updateHulls = [HashedCells{t}.hullID];

    % TODO: keep around long term graphedits for prevHulls?
    forwardEdits = find(any((GraphEdits(prevHulls,:) ~= 0),1));
    bLongEdits = ([CellHulls(forwardEdits).time] > (t+1));
    Tracker.GraphEditsResetHulls(forwardEdits(bLongEdits), 0, 1);
    
    Tracker.UpdateTrackingCosts(t, updateHulls, newHulls);
    updateDijkstraGraph(updateHulls, newHulls);
    
    nextHulls = [HashedCells{t+1}.hullID];
    [costMatrix bOutTracked bInTracked] = Tracker.GetCostSubmatrix(prevHulls, nextHulls);
    fromHulls = prevHulls(bOutTracked);
    toHulls = nextHulls(bInTracked);

    % Tree-preserving assignment code
    newPreserveTracks = reassignPreserveEdges(costMatrix, fromHulls, toHulls, preserveTracks);
    
    %TODO: go ahead and update tracking, but no need to reassign since we now
    % hit every frame that has valid tracks.
    
    % Update Tracking to next frame
    if ( (t+1) < length(HashedCells) )
        nextHulls = [HashedCells{t+2}.hullID];
        if ( isempty(nextHulls) || isempty(toHulls) )
            return;
        end
        
        Tracker.UpdateTrackingCosts(t+1, toHulls, nextHulls);
        updateDijkstraGraph(toHulls, nextHulls);
    end
end

function bAccept = inPreserveTrack(startVert, endVert, acceptTracks)
    bAccept = 0;
    if ( ismember(Hulls.GetTrackID(endVert), acceptTracks) )
        bAccept = 1;
    end
    
end

function newPreserveTracks = reassignPreserveEdges(costMatrix, fromHulls, toHulls, preserveTracks)
    global CellHulls CellTracks HashedHulls
    
    newPreserveTracks = [];
    
    fromTime = CellHulls(fromHulls(1)).time;
    
    preserveStarts = [CellTracks(preserveTracks).startTime];
    preserveEnds = [CellTracks(preserveTracks).endTime];
    inPreserveTracks = preserveTracks((preserveStarts <= fromTime+1) & (preserveEnds >= fromTime+1));
%     preserveEdges = getPreserveEdges(fromHulls, preserveTracks);
%     [chkHulls oldAssign] = getAssignedTracks(preserveEdges);

    % TODO: Remove all preserve-tracks at t+1, get new track IDs, assign
    % hulls to preserve-tracks after removing all current hulls (track list
    % and hull list match, reconnect w/ children if necessary).
    % After all that, run changelabel/add mitosis code to link edges.
    droppedTracks = [];
    for i=1:length(inPreserveTracks)
        droppedTracks = union(droppedTracks,Families.RemoveFromTreePrune(inPreserveTracks(i), fromTime+1));
    end
    
%     % Update tracking forward from split frame
%     if ( fromTime < (length(HashedHulls)+1) )
%         nextHulls = [HashedHulls{fromTime+2}.hullID];
%         Tracker.UpdateTrackingCosts(t+1, toHulls, nextHulls);
%         updateDijkstraGraph(toHulls, nextHulls);
%     end
%     
%     % Guess best preserveTrack assignments using Dijkstra
%     dijkstraCosts = Inf*ones(length(toHulls),length(droppedTracks));
%     acceptFunc = @(startVert,endVert)(inPreserveTrack(startVert, endVert, droppedTracks));
%     for i=1:length(toHulls)
%         [paths pathCosts] = mexDijkstra('matlabExtend', toHulls(i), 10, acceptFunc);
%         for j=1:length(paths)
%             pathTrack = Hulls.GetTrackID(paths{j}(end));
%             costIdx = find(pathTrack == droppedTracks);
%             dijkstraCosts(i,costIdx) = min(dijkstraCosts(i,costIdx), pathCosts(j));
%         end
%     end
%     
%     % TODO: Assign using dijkstra if possible? Fall back otherwise?
%     assignIdx = assignmentoptimal(dijkstraCosts);
%     bValid = (assignIdx > 0);
%     assignNextToTrack = zeros(1,length(toHulls));
%     assignNextToTrack(bValid) = droppedTracks(assignIdx(bValid));
    
    % find t to t+1 assignments
    [assignIdx assignOut] = findMinAssignment(costMatrix);
    allEdges = [(fromHulls(assignIdx)') (toHulls(assignOut)')];
    
    [mitIdx mitOut] = findMitosisEdges(costMatrix, [(assignIdx') (assignOut')], length(inPreserveTracks));
    mitEdges = [zeros(0,2); (fromHulls(mitIdx)') (toHulls(mitOut)')];
    
    allEdges = [allEdges; mitEdges];
    
%     if ( size(allEdges,1) <  length(inPreserveTracks) )
%         error('Unable to find sufficient edges to preserve tree events');
%     end
    
    % Assign all hulls to next frames
    [bOnTrack trackIdx] = ismember(Hulls.GetTrackID(allEdges(:,2)), droppedTracks);
    trackIdx(~bOnTrack) = setdiff(1:length(droppedTracks),trackIdx(bOnTrack));
    assignToTrack = droppedTracks(trackIdx);
    
    relinkTracks = cell(length(assignToTrack), 1);
    for i=1:length(assignToTrack)
        curTrack = Hulls.GetTrackID(allEdges(i,2));
        if ( curTrack == assignToTrack(i) )
            continue;
        end
        
        curHull = Tracks.GetHullID(fromTime+1, assignToTrack(i));
        if ( curHull ~= 0 )
            relinkTracks{i} = Tracks.RemoveHullFromTrack(curHull);
            Families.NewCellFamily(curHull);
        end
        
        oldDropped = Tracks.RemoveHullFromTrack(allEdges(i,2));
        
        assignIdx = find(curTrack == assignToTrack);
        if ( ~isempty(assignIdx) )
            relinkTracks{assignIdx} = oldDropped;
        end
        
        Tracks.AddHullToTrack(allEdges(i,2), assignToTrack(i));
    end
    
    for i=1:length(relinkTracks)
        if ( isempty(relinkTracks{i}) )
            continue;
        end
        
        Families.ReconnectParentWithChildren(assignToTrack(i), relinkTracks{i});
    end
    
    newPreserveTracks = [];
    for i=1:size(allEdges,1)
        parentTrackID = Hulls.GetTrackID(allEdges(i,1));
        childTrackID = Hulls.GetTrackID(allEdges(i,2));
        
        childTime = CellTracks(childTrackID).startTime;
        
        parentHull = Tracks.GetHullID(childTime, parentTrackID);
        if ( parentHull > 0 )
            Families.AddToTree(childTrackID, parentTrackID);
            newPreserveTracks = [newPreserveTracks CellTracks(parentTrackID).childrenTracks];
        else
            Tracks.ChangeLabel(childTrackID, parentTrackID, childTime);
            newPreserveTracks = [newPreserveTracks parentTrackID];
        end
    end
    
    newPreserveTracks = setdiff(newPreserveTracks, preserveTracks);
end

function [assignIdx assignOut] = findMinAssignment(costMatrix)
    [minInCosts,bestIncoming] = min(costMatrix,[],1);
    [minOutCosts,bestOutgoing] = min(costMatrix,[],2);
    
    if ( isempty(costMatrix) )
        return;
    end
    
    bestOutgoing  = bestOutgoing';
    bMatched = (bestIncoming(bestOutgoing) == (1:length(bestOutgoing)));
    matchedIdx = find(bMatched);
    
    costMatrix(matchedIdx, :) = Inf;
    costMatrix(:, bestOutgoing(matchedIdx)) = Inf;
    
    assignIdx = matchedIdx;
    assignOut = bestOutgoing(matchedIdx);
    
    % Patch and assign as many fromHulls as possible.
    [minCost minIdx] = min(costMatrix(:));
    [minR minC] = ind2sub(size(costMatrix), minIdx);
    while ( (minCost < Inf) )
        assignIdx = [assignIdx minR];
        assignOut = [assignOut minC];
        
        costMatrix(minR, :) = Inf;
        costMatrix(:, minC) = Inf;
        
        [minCost minIdx] = min(costMatrix(:));
        [minR minC] = ind2sub(size(costMatrix), minIdx);
    end
end

function [mitIdx mitOut] = findMitosisEdges(costMatrix, localEdges, numOldEdges)

    mitIdx = [];
    mitOut = [];

    needEdges = numOldEdges - size(localEdges,1);
    
    costMatrix(:,localEdges(:,2)) = Inf;
    for i=1:needEdges
        [minCost minIdx] = min(costMatrix(:));
        [minR minC] = ind2sub(size(costMatrix), minIdx);
        
        if ( isinf(minCost) )
            return;
        end
        
        edgeCount = nnz(minR == localEdges(:,1));
        if ( edgeCount < 2 )
            costMatrix(:,minC) = Inf;
            
            mitIdx = [mitIdx minR];
            mitOut = [mitOut minC];
            
            localEdges = [localEdges; minR minC];
            
            if ( edgeCount == 1 )
                costMatrix(minR,:) = Inf;
            end
        else
            costMatrix(minR,:) = Inf;
        end
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
