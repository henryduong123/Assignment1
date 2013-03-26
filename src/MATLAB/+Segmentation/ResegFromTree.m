% segEdits = ResegFromTree(rootTracks)
% 
% Attempt to correct segmentation (and tracking) errors by exploiting a
% corrected lineage tree.
% 
% rootTracks - List of root tree tracks to resegment

function tLast = ResegFromTree(rootTracks, tStart, tEnd)
    global HashedCells CellTracks CellHulls Costs
    
    global Figures CONSTANTS
    outMovieDir = fullfile('B:\Users\mwinter\Documents\Figures\Reseg',CONSTANTS.datasetName);
    
    if ( ~exist('tStart','var') )
        tStart = 2;
    end
    
    if ( ~exist('tEnd','var') )
        tEnd = length(HashedCells);
    end
    
    tStart = max(tStart,2);
    tMax = length(HashedCells);
    tEnd = min(tEnd, tMax);
    
    checkTracks = Segmentation.Reseg.GetSubtreeTracks(rootTracks);
    
    invalidPreserveTracks = [];
    
    % Need to worry about deleted hulls?
    costMatrix = Costs;
    bDeleted = ([CellHulls.deleted] > 0);
    costMatrix(bDeleted,:) = 0;
    costMatrix(:,bDeleted) = 0;
    
    mexDijkstra('initGraph', costMatrix);
    
    for t=tStart:tEnd
        checkTracks = setdiff(checkTracks, invalidPreserveTracks);
        
        newPreserveTracks = fixupFrame(t, checkTracks, tMax);
        
        checkTracks = [checkTracks newPreserveTracks];
        [dump sortedIdx] = unique(checkTracks, 'first');
        sortedIdx = sort(sortedIdx);
        checkTracks = checkTracks(sortedIdx);
        
        bInvalidPreserveTracks = cellfun(@(x)(isempty(x)),{CellTracks(checkTracks).startTime});
        invalidPreserveTracks = checkTracks(bInvalidPreserveTracks);
        
        % DEBUG
        Figures.time = t;
        validPreserveTracks = checkTracks(~bInvalidPreserveTracks);
        famID = CellTracks(validPreserveTracks(1)).familyID;
        
        UI.DrawTree(famID);
        UI.TimeChange(t);
        drawnow();
        
        % Make Movie code
%         saveMovieFrame(t, famID, outMovieDir);
        
        tLast = t;
    end
    
%     saveMovieFrame(1, famID, outMovieDir);
end

function saveMovieFrame(t, famID, outdir)
    global Figures CONSTANTS
    
    UI.DrawTree(famID);
    UI.TimeChange(t);
    drawnow();
    
    if ( ~exist(outdir, 'dir') )
        recmkdir(outdir);
    end
    
    figure(Figures.cells.handle)
    XCells = getframe();
    imwrite(XCells.cdata, fullfile(outdir,['cells_' CONSTANTS.datasetName num2str(t, '%04d') '.tif']), 'tiff');

    figure(Figures.tree.handle)
    XTree = getframe();
    imwrite(XTree.cdata, fullfile(outdir,['tree_' CONSTANTS.datasetName num2str(t, '%04d') '.tif']), 'tiff');
    
    frameSize = [size(XCells.cdata); size(XTree.cdata)];
    outSize = max(frameSize,[],1);
    imOut = [imresize(XCells.cdata, outSize(1:2)) imresize(XTree.cdata, outSize(1:2))];
    imwrite(imOut, fullfile(outdir,['_comb_' CONSTANTS.datasetName num2str(t, '%04d') '.tif']), 'tiff');
end

function newPreserveTracks = fixupFrame(t, preserveTracks, tEnd)
    global CellTracks HashedCells
    bInTracks = (([CellTracks(preserveTracks).startTime] <= t) & ([CellTracks(preserveTracks).endTime] >= t));
    
    if ( nnz(bInTracks) == 0 )
        return;
    end
    
    inPreserveTracks = preserveTracks(bInTracks);
    
    % Disconnect all tracks (t-1) -> t.
    [droppedTracks oldEdges] = chopTracks(t, inPreserveTracks);
    
    % Find best (t-1) -> t assignment (adding/splitting hulls)
    newEdges = findBestReseg(t, oldEdges);
    
    % Update tracking costs and dijkstra internal state
    updateHulls = [HashedCells{t-1}.hullID];
    tHulls = [HashedCells{t}.hullID];
    
    Tracker.UpdateTrackingCosts(t-1, updateHulls, tHulls);
    
    updateDijkstraGraph(t-1);
    updateDijkstraGraph(t);
    
    % Use Dijkstra or just manually find best t -> (t+1) assignment, and
    % move hulls in frame t into the appropriate dropped tracks
    if ( t < tEnd )
        newEdges = reassignNextHulls(t, droppedTracks, newEdges);
    end
    
    % Do appropriate linking up of tracks from (t-1) -> t as found above
    newPreserveTracks = linkupEdges(newEdges, preserveTracks);
    
    if ( t < length(HashedCells) )
        Tracker.UpdateTrackingCosts(t, tHulls, [HashedCells{t+1}.hullID]);
    end
end

function newPreserveTracks = linkupEdges(edges, preserveTracks)
    global CellTracks
    
    newPreserveTracks = [];
    for i=1:size(edges,1)
        parentTrackID = Hulls.GetTrackID(edges(i,1));
        childTrackID = Hulls.GetTrackID(edges(i,2));
        
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

function newEdges = reassignNextHulls(t, droppedTracks, newEdges)
    global CellTracks CellHulls 
    
    if ( length(droppedTracks) ~= size(newEdges,1) )
        error('There are too few edges to preserve structure!');
    end
    
    % Use Dijkstra to assign t->t+1 edges (except mitosis edges, don't
    % break those!)
    
    assignToTrack = zeros(size(newEdges,1),1);
    
	termHulls = zeros(1,size(newEdges,1));
    for i=1:length(droppedTracks)
        termHulls(i) = Helper.GetNearestTrackHull(droppedTracks(i), t+1, +1);
    end
    
    bCurrentMitosis = (arrayfun(@(x)((~isempty(x.childrenTracks)) & (x.endTime == t)), CellTracks(droppedTracks)));
    
    if ( any((termHulls == 0) & ~bCurrentMitosis) )
        error('There are no hulls on dropped track after frame t!');
    end
    
    forwardCosts = Inf*ones(size(newEdges,1), size(newEdges,1));
    
    % Use Dijkstra to find other costs
    maxT = max([CellHulls(termHulls(~bCurrentMitosis)).time]);
    
    % Handle the case that only mitosis event options exist
    if ( isempty(maxT) )
        maxT = max(horzcat(CellHulls(newEdges(:,2)).time) + 5);
    end
    
    for i=1:size(newEdges,1)
        extendHull = newEdges(i,2);
        if ( extendHull == 0 )
            extendHull = newEdges(i,1);
        end
        
        maxExt = maxT - CellHulls(extendHull).time + 1;
        
        [endpaths endCosts] = mexDijkstra('matlabExtend', extendHull, maxExt, @(x,y)(any(y==termHulls)), 1, 0);
        lastHulls = cellfun(@(x)(x(end)), endpaths);
        [bFoundPath arrIdx] = ismember(termHulls, lastHulls);
        
        forwardCosts(i,bFoundPath) = endCosts(arrIdx(bFoundPath));
    end
    
    % Deal with mitosis events
    currentMitosis = find(bCurrentMitosis);
    for i=1:length(currentMitosis)
        childrenTracks = CellTracks(droppedTracks(currentMitosis(i))).childrenTracks;
        leftHull = Helper.GetNearestTrackHull(childrenTracks(1), t+1, +1);
        rightHull = Helper.GetNearestTrackHull(childrenTracks(2), t+1, +1);
        
        if ( leftHull == 0 || rightHull == 0 )
            error('Badly defined mitosis event, parent hull not followed by two child hulls');
        end
        
        totalCosts = Inf*ones(size(newEdges,1),1);
        bRealHullIdx = (newEdges(:,2) ~= 0);
        
        mitCosts = getNextCosts(t,newEdges(bRealHullIdx,2), [leftHull rightHull]);
        totalCosts(bRealHullIdx) = sum(mitCosts,2);
        
        [minCost bestFromIdx] = min(totalCosts);
        if ( isinf(minCost) )
            error('There is no hull in frame t from which to build the mitosis event');
        end
        
        forwardCosts(bestFromIdx,:) = Inf;
        forwardCosts(:,currentMitosis(i)) = Inf;
        forwardCosts(bestFromIdx,currentMitosis(i)) = 1;
    end
    
    assignIdx = assignmentoptimal(forwardCosts);
    notAssigned = find(assignIdx == 0);
    if ( ~isempty(notAssigned) )
        % If all else fails assign arbitrarily
        for i=1:length(notAssigned)
            bInf = isinf(forwardCosts(notAssigned(i),:));
            forwardCosts(notAssigned(i),bInf) = 1e10;
        end
        
        assignIdx = assignmentoptimal(forwardCosts);
        if ( any(assignIdx == 0) )
            error('Unable to assign all t->t+1 edges');
        end
    end
    
    for i=1:size(newEdges,1)
        if ( newEdges(i,2) == 0 )
            newEdges(i,2) = termHulls(assignIdx(i));
            continue;
        end
        
        assignToTrack(i) = droppedTracks(assignIdx(i));
    end
    
%     % Assign all hulls to next frames
%     [bOnTrack trackIdx] = ismember(Hulls.GetTrackID(newEdges(bnzEdges,2)), droppedTracks);
%     trackIdx(~bOnTrack) = setdiff(1:length(droppedTracks),trackIdx(bOnTrack));
%     assignToTrack = droppedTracks(trackIdx);
    
    relinkTracks = cell(length(assignToTrack), 1);
    for i=1:length(assignToTrack)
        if ( assignToTrack(i) == 0 )
            continue;
        end
        
        curTrack = Hulls.GetTrackID(newEdges(i,2));
        if ( curTrack == assignToTrack(i) )
            continue;
        end
        
        curHull = Tracks.GetHullID(t, assignToTrack(i));
        if ( curHull ~= 0 )
            relinkTracks{i} = Tracks.RemoveHullFromTrack(curHull);
            Families.NewCellFamily(curHull);
        end
        
        oldDropped = Tracks.RemoveHullFromTrack(newEdges(i,2));
        
        assignIdx = find(curTrack == assignToTrack);
        if ( ~isempty(assignIdx) )
            relinkTracks{assignIdx} = oldDropped;
        end
        
        Tracks.AddHullToTrack(newEdges(i,2), assignToTrack(i));
    end
    
    for i=1:length(relinkTracks)
        if ( isempty(relinkTracks{i}) )
            continue;
        end
        
        Families.ReconnectParentWithChildren(assignToTrack(i), relinkTracks{i});
    end
end

function [droppedTracks edges] = chopTracks(t, tracks)
    global CellTracks;
    
    droppedTracks = [];
    
    edges = [];
    % Find edges (hull-to-hull) that span t
    for i=1:length(tracks)
        chkEdge = getTrackInEdge(t, tracks(i));
        if ( isempty(chkEdge) )
            error(['Not all preserve tracks in frame ' num2str(t) ' have edges through frame ' num2str(t)]);
        end
        
        edges = [edges; chkEdge];
    end
    
    % Drop tracks at frame t
    for i=1:length(tracks)
        droppedTracks = union(droppedTracks, Families.RemoveFromTreePrune(tracks(i), t));
    end
    
    % Associate edges with droppedTracks
    startHulls = arrayfun(@(x)(x.hulls(1)), CellTracks(droppedTracks));
    [bDropped srtIdx] = ismember(edges(:,2), startHulls);
    
    if ( ~all(bDropped) )
        error(['Not all preserve tracks were chopped ' num2str(t)]);
    end
    
    edges = edges(srtIdx, :);
end


function newEdges = findBestReseg(t, curEdges)
    global CellHulls HashedCells
    
    newEdges = [];
    
    if ( isempty(curEdges) )
        return;
    end
    
    tFrom = [CellHulls(curEdges(:,1)).time];
    tTo = [CellHulls(curEdges(:,2)).time];
    
    bLongEdge = ((t-tFrom) > 1);
    
%     checkEdges = curEdges(~bLongEdge,:);
    checkEdges = curEdges;
    
    [checkHulls uniqueIdx] = unique(checkEdges(:,1));
    nextHulls = [HashedCells{t}.hullID];
    
    % Find mitosis edges
    mitIdx = setdiff(1:size(checkEdges,1), uniqueIdx);
    mitosisParents = checkEdges(mitIdx,1);
    
    costMatrix = getNextCosts(t-1, checkHulls, nextHulls);
    
    % TODO: Do I need to handle erroneous missed mitoses?
    missIdx = find(bLongEdge(uniqueIdx));
    for i=1:length(missIdx)
        extendHull = checkHulls(missIdx(i));
        maxExt = t - CellHulls(extendHull).time + 1;
        
        [endpaths endCosts] = mexDijkstra('matlabExtend', extendHull, maxExt, @(x,y)(any(y==nextHulls)), 1, 0);
        lastHulls = cellfun(@(x)(x(end)), endpaths);
        [bFoundPath arrIdx] = ismember(nextHulls, lastHulls);
        
        costMatrix(missIdx(i),bFoundPath) = endCosts(arrIdx(bFoundPath));
    end

    % TODO: handle this better in the case of a not completely edited tree.
    % Force-keep mitosis edges
    for i=1:length(mitosisParents)
        mitChkIdx = find(checkHulls == mitosisParents(i),1,'first');
        childHulls = checkEdges((checkEdges(:,1) == mitosisParents(i)), 2);
        [bDump childIdx] = ismember(childHulls, nextHulls);

        costMatrix(mitChkIdx,:) = Inf*ones(1,size(costMatrix,2));
        costMatrix(mitChkIdx,childIdx) = 1;
    end
    
    bAddedHull = false(size(checkHulls,1),1);
    % TODO: This probably doesn't work very well
    % Try to add hulls 
    for i=1:length(checkHulls)
        if ( ismember(checkHulls(i),mitosisParents) )
            continue;
        end
        
        if ( any(i == missIdx) )
            continue
        end
        
        overlapDist = getOverlapDist(checkHulls(i), nextHulls);
        minOverlap = min(overlapDist);
        if ( minOverlap > 2.0 )
            [addedHull costMatrix nextHulls] = tryAddSegmentation(checkHulls(i), costMatrix, checkHulls, nextHulls);
            if ( isempty(addedHull) )
                if ( ~all(isinf(costMatrix(i,:))) )
                    continue;
                end
                
                [addedHull costMatrix nextHulls] = tryAddSegmentation(checkHulls(i), costMatrix, checkHulls, nextHulls, 1);
                
                if ( isempty(addedHull) )
                    continue;
                end
            end
            
            bAddedHull(i) = 1;
        end
    end
    
    % Find hulls we may need to split
    desiredCellCount = zeros(length(nextHulls),1);
    desirers = cell(length(nextHulls),1);
    for i=1:length(checkHulls)
        [desiredCosts desiredIdx] = sort(costMatrix(i,:));
        if ( bAddedHull(i) )
            continue;
        end
        
        % TODO: Handle this case.
        if ( isinf(desiredCosts(1)) && ~any(i == missIdx) )
            error('Did not add hull but unable to find next hull to go to');
        end
        
        desiredCellCount(desiredIdx(1)) = desiredCellCount(desiredIdx(1)) + 1;
        
        desirers{desiredIdx(1)} = [desirers{desiredIdx(1)} checkHulls(i)];
        
        if ( ismember(checkHulls(i),mitosisParents) )
            desiredCellCount(desiredIdx(2)) = desiredCellCount(desiredIdx(2)) + 1;
            desirers{desiredIdx(2)} = [desirers{desiredIdx(2)} checkHulls(i)];
        end
    end
    
    % Try to split hulls
    splitIdx = find(desiredCellCount > 1);
    for i=1:length(splitIdx)
        [newSegs costMatrix nextHulls] = trySplitSegmentation(nextHulls(splitIdx(i)), desiredCellCount(splitIdx(i)), desirers{splitIdx(i)}, mitosisParents, costMatrix, checkHulls, nextHulls);
    end
    
    % TODO: assign mitosis edges first without bothering to change, can
    % do this by making sure the mitosis hull is assigned correctly in the
    % split code
    
    % Find matched tracks and assign, then assign everything else by
    % "patching"
    [bestOutgoing bestOutIdx] = min((costMatrix'),[],1);
    [bestIncoming bestInIdx] = min(costMatrix,[],1);
    
    bValidMatched = ((bestInIdx(bestOutIdx) == 1:size(costMatrix,1)) & (~isinf(bestOutgoing)));
    matchedIdx = find(bValidMatched);
    
    newEdges = [];
    
    % Create the edge list
    for i=1:length(matchedIdx)
        chkIdx = matchedIdx(i);
        
        hullIdx = checkHulls(chkIdx);
        assignNextIdx = nextHulls(bestOutIdx(chkIdx));
        
        newEdges = [newEdges; hullIdx assignNextIdx];
        if ( ismember(hullIdx,mitosisParents) )
            [sortCost sortIdx] = sort(costMatrix(chkIdx,:));
            assignChildIdx = nextHulls(sortIdx(2));
            
            newEdges = [newEdges; hullIdx assignChildIdx];
            costMatrix(:,sortIdx(2)) = Inf;
        end
        
        costMatrix(chkIdx,:) = Inf;
        costMatrix(:,bestOutIdx(chkIdx)) = Inf;
    end
    
    [minCost minIdx] = min(costMatrix(:));
    while ( ~isinf(minCost) )
        [minR minC] = ind2sub(size(costMatrix), minIdx);
        
        hullIdx = checkHulls(minR);
        assignNextIdx = nextHulls(minC);
        
        newEdges = [newEdges; hullIdx assignNextIdx];
        costMatrix(minR,:) = Inf;
        costMatrix(:,minC) = Inf;
        
        [minCost minIdx] = min(costMatrix(:));
    end
    
    % TODO: Use dijkstra or some other method to "share" hulls, Keep this
    % info around so that these shares can get back into the mix later
    shareEdges = [];
    missedHulls = curEdges(~ismember(curEdges(:,1), newEdges(:,1)), 1);
    if ( ~isempty(missedHulls) )
        missedEdges = curEdges(ismember(curEdges(:,1),missedHulls),:);
        for i=1:size(missedEdges,1)
            shareEdges = [shareEdges; missedEdges(i,1) 0];
        end
    end
    
    newEdges = [newEdges; shareEdges];
    
end

function updateDijkstraGraph(t)
    global HashedCells
    
    if ( t < 1 || t+1 > length(HashedCells) )
        return;
    end
    
    updateHulls = [HashedCells{t}.hullID];
    nextHulls = [HashedCells{t+1}.hullID];

    costMatrix = getNextCosts(t, updateHulls, nextHulls);
    if ( isempty(costMatrix) )
        return;
    end
    
    mexDijkstra('updateGraph', costMatrix, updateHulls, nextHulls);
end

function [addedHull costMatrix nextHulls] = tryAddSegmentation(prevHull, costMatrix, checkHulls, nextHulls, bAggressive)
    global CONSTANTS CellHulls HashedCells

    if ( ~exist('bAggressive','var') )
        bAggressive = 0;
    end
    
    addedHull = [];
    
    time = CellHulls(prevHull).time + 1;
    
    fileName = Helper.GetFullImagePath(time);
    img = Helper.LoadIntensityImage(fileName);
    
    guessPoint = [CellHulls(prevHull).centerOfMass(2) CellHulls(prevHull).centerOfMass(1)];
    
    newObj = Segmentation.PartialImageSegment(img, guessPoint, 200, 1.0, CellHulls(prevHull).indexPixels);
    
    if ( isempty(newObj) )
        if ( ~bAggressive )
            return;
        end
        
        for tryAlpha = 0.95:(-0.05):0.5
            newObj = Segmentation.PartialImageSegment(img, guessPoint, 200, tryAlpha, CellHulls(prevHull).indexPixels);
            if ( ~isempty(newObj) )
                break;
            end
        end
        
        if ( isempty(newObj) )
            return;
        end
    end
    
    newHull = struct('time', [], 'points', [], 'centerOfMass', [], 'indexPixels', [], 'imagePixels', [], 'deleted', 0, 'userEdited', 0);
    
    newHull.time = time;
    newHull.points = newObj.points;
    
    % Remove overlap with other hulls in the frame
    checkAllHulls = [HashedCells{time}.hullID];
    nextPix = vertcat(CellHulls(checkAllHulls).indexPixels);
    objPix = newObj.indPixels(~ismember(newObj.indPixels,nextPix));
    
    if ( length(objPix) < 20 )
        return;
    end
    
    newObj.indPixels = objPix;
    [r c] = ind2sub(CONSTANTS.imageSize, objPix);
    
    ch = convhull(r,c);
    
    newHull.centerOfMass = mean([r c]);
    newHull.indexPixels = newObj.indPixels;
    newHull.imagePixels = newObj.imPixels;
    
    newHull.points = [c(ch),r(ch)];
    
    % Use temporary hull to verify cost (not on a track yet)
    chkIdx = find(checkHulls == prevHull);
    chkCosts = getTempCosts(time-1, checkHulls, newHull);
    
    % [minCost minIdx] = min(chkCosts);
    % if ( minIdx ~= chkIdx )
    %     error('Not best incoming cost');
    % end
    
    % If will prefer something else over the added 
    prevEdgeCost = chkCosts(chkIdx);
    if ( prevEdgeCost > min(costMatrix(chkIdx,:)) )
        return;
    end
    
    addedHull = Hulls.SetHullEntries(0, newHull);
    
    nextHulls = [nextHulls addedHull];
    costMatrix = [costMatrix chkCosts];
end

function newHulls = tryResegDeterministic(hull, k, checkHullIDs)
    global CONSTANTS CellHulls
    
    newHulls = [];
    
    hullTimes = unique([CellHulls(checkHullIDs).time]);
    if ( length(hullTimes) > 1 )
        newHulls = Segmentation.ResegmentHull(hull, k);
        return;
    end
    
    oldMeans = zeros(k,2);
    for i=1:length(checkHullIDs)
        [r c] = ind2sub(CONSTANTS.imageSize, CellHulls(checkHullIDs(i)).indexPixels);
        oldMeans(i,:) = mean([c r],1);
    end
    
    [r c] = ind2sub(CONSTANTS.imageSize, hull.indexPixels);
    if ( strcmpi(CONSTANTS.cellType,'Adult') )
        % Cheat and initially cluster about equiprobably
        com = mean([c r],1);
        oldCom = mean(oldMeans,1);
        deltaCom = com - oldCom;
        
        distSq = zeros(length(r), k);
%         startVar = ones(k,1);
        for i=1:length(checkHullIDs)
            oldMeans(i,:) = oldMeans(i,:) + deltaCom;
%             dcomSq(i) = (com(1)-oldMeans(i,1)).^2 + (com(2)-oldMeans(i,2)).^2;
            
            distSq(:,i) = ((c-oldMeans(i,1)).^2 + (r-oldMeans(i,2)).^2);
        end
        
        [minDist minIdx] = min(distSq,[],2);
        gmoptions = statset('Display','off', 'MaxIter',400);
        obj = gmdistribution.fit([c,r], k, 'Start',minIdx, 'Regularize',0.5 , 'Options',gmoptions);
        kIdx = cluster(obj, [c,r]);
    elseif ( strcmpi(CONSTANTS.cellType,'Hemato') )
        [kIdx centers] = kmeans([c,r], k, 'start',oldMeans, 'EmptyAction','drop');
    else
        [kIdx centers] = kmeans([c,r], k, 'start',oldMeans, 'EmptyAction','drop');
    end
    
    if ( any(isnan(kIdx)) )
        return;
    end

    connComps = cell(1,k);

    nh = struct('time', [], 'points', [], 'centerOfMass', [], 'indexPixels', [], 'imagePixels', [], 'deleted', 0, 'userEdited', 0);
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

        connComps{i} = hull.indexPixels(bIdxPix);

        nh.indexPixels = hull.indexPixels(bIdxPix);
        nh.imagePixels = hull.imagePixels(bIdxPix);
        nh.centerOfMass = mean([hy hx]);
        nh.time = hull.time;

        try
            chIdx = convhull(hx, hy);
        catch excp
            newHulls = [];
            return;
        end

        nh.points = [hx(chIdx) hy(chIdx)];

        newHulls = [newHulls nh];
    end

    % Define an ordering on the hulls selected, COM is unique per component so
    % this gives a deterministic ordering to the components
    [sortCOM, sortIdx] = sortrows(vertcat(newHulls.centerOfMass));
    newHulls = newHulls(sortIdx);
    connComps = connComps(sortIdx);
    
end

function [newSegs costMatrix nextHulls] = trySplitSegmentation(splitHull, numSplit, prevHulls, mitosisParents, costMatrix, checkHulls, nextHulls)
    global CellHulls HashedCells

    newSegs = [];
    
    if ( numSplit == 1 )
        newSegs = splitHull;
        return;
    end
    
    newHulls = tryResegDeterministic(CellHulls(splitHull), numSplit, prevHulls);
    % newHulls = Segmentation.ResegmentHull(CellHulls(splitHull), numSplit);
    if ( isempty(newHulls) )
        return;
    end
    
    for i=1:length(newHulls)
        newHulls(i).userEdited = 0;
    end
    
    % TODO: fixup incoming graphedits
    
    % TODO: Deal with mitosis events, 
    % TODO: This definitely needs work
    t = max([CellHulls(checkHulls).time]);
    newCosts = getTempCosts(t, checkHulls, newHulls);
    
    % Just set long edges to a uniformly high cost
    bLongEdge = ([CellHulls(checkHulls).time] < t);
    newCosts(bLongEdge,:) = 1e20;
    
    splitIdx = find(nextHulls == splitHull,1,'first');
    [bHadMitosis mitIdx] = ismember(prevHulls, mitosisParents);
    
    [bDump prevIdx] = ismember(prevHulls, checkHulls);
    
    bAssignHullIdx = false(1,length(newHulls));
    bAssignHullIdx(1) = 1;
    if ( any(bHadMitosis) )
        [bestMitCost bestMitIdx] = min(newCosts(prevIdx(bHadMitosis),:));
        
        newCosts(prevIdx(bHadMitosis),:) = Inf;
        newCosts(prevIdx(bHadMitosis),bestMitIdx) = 1;
        
        bAssignHullIdx(1) = 0;
        bAssignHullIdx(bestMitIdx) = 1;
    end
    
    % Force a hungarian assignment for splits
    assignIdx = assignmentoptimal(newCosts(prevIdx,:));
    for i=1:length(assignIdx)
        newCosts(prevIdx(i),:) = Inf;
        newCosts(prevIdx,assignIdx(i)) = Inf;
        
        newCosts(prevIdx(i),assignIdx(i)) = 3;
    end
    
    setHullIDs = zeros(1,length(newHulls));
    setHullIDs(bAssignHullIdx) = splitHull;
    % Just arbitrarily assign clone's hull for now
    newSegs = Hulls.SetHullEntries(setHullIDs, newHulls);
    
    updateIdx = find(nextHulls == splitHull);
    
    costMatrix(:,updateIdx) = newCosts(:,bAssignHullIdx);
    costMatrix = [costMatrix newCosts(:,~bAssignHullIdx)];
    nextHulls = [nextHulls newSegs(~bAssignHullIdx)];
end

function dist = getOverlapDist(fromHull, toHulls)
    global CellHulls
    
    dist = Inf*ones(1,length(toHulls));
    
    if ( isempty(toHulls) )
        return;
    end
    
    t = CellHulls(fromHull).time;
    tNext = CellHulls(toHulls(1)).time;
    
    if ( (tNext - t) <= 2 )
        for i=1:length(toHulls)
            dist(i) = Tracker.GetConnectedDistance(fromHull, toHulls(i));
        end
        return;
    end
    
    comDistSq = sum((ones(length(toHulls),1)*CellHulls(fromHull).centerOfMass - vertcat(CellHulls(toHulls).centerOfMass)).^2, 2);
    
    checkIdx = find(comDistSq <= ((tDist*CONSTANTS.dMaxCenterOfMass)^2));
    
    [r c] = ind2sub(CONSTANTS.imageSize, CellHulls(fromHull).indexPixels);
    for i=1:length(checkIdx)
        [rNext cNext] = ind2sub(CONSTANTS.imageSize, CellHulls(toHulls(checkIdx(i))).indexPixels);
        
        isect = intersect(CellHulls(fromHull).indexPixels, CellHulls(toHulls(checkIdx(i))).indexPixels);
        if ( ~isempty(isect) )
            isectDist = 1 - (length(isect) / min(length(CellHulls(fromHull).indexPixels), length(CellHulls(toHulls(checkIdx(i))).indexPixels)));
            dist(checkIdx(i)) = isectDist;
            continue;
        end
        
        ccMinDistSq = Inf;
        for k=1:length(r)
            ccDistSq = (rNext-r(k)).^2 + (cNext-c(k)).^2;
            ccRowMin = min(ccDistSq);
            if ( ccRowMin < ccMinDistSq )
                ccMinDistSq = ccRowMin;
            end
            
            if ( ccRowMin < 1 )
                break;
            end
        end
        
        if ( ccMinDistSq > (CONSTANTS.dMaxConnectComponent^2) )
            continue;
        end
        
        dist(checkIdx(i)) = sqrt(ccMinDistSq);
    end
end

function connDist = updateTempConnDist(updateHulls, hulls, hash)
    global ConnectedDist
    
    connDist = ConnectedDist;
    
    for i=1:length(updateHulls)
        if ( hulls(updateHulls(i)).deleted )
            continue;
        end
        
        connDist{updateHulls(i)} = [];
        t = hulls(updateHulls(i)).time;
        
        connDist = updateDistances(updateHulls(i), t, t+1, connDist, hulls, hash);
        connDist = updateDistances(updateHulls(i), t, t+2, connDist, hulls, hash);
        
        connDist = updateDistances(updateHulls(i), t, t-1, connDist, hulls, hash);
        connDist = updateDistances(updateHulls(i), t, t-2, connDist, hulls, hash);
    end
end

function connDist = updateDistances(updateCell, t, tNext, connDist, hulls, hash)
    global CONSTANTS
    
    if ( tNext < 1 || tNext > length(hash) )
        return;
    end
    
    tDist = abs(tNext-t);
    
    nextCells = [hash{tNext}.hullID];
    
    if ( isempty(nextCells) )
        return;
    end
    
    comDistSq = sum((ones(length(nextCells),1)*hulls(updateCell).centerOfMass - vertcat(hulls(nextCells).centerOfMass)).^2, 2);
    
    nextCells = nextCells(comDistSq <= ((tDist*CONSTANTS.dMaxCenterOfMass)^2));

    [r c] = ind2sub(CONSTANTS.imageSize, hulls(updateCell).indexPixels);
    for i=1:length(nextCells)
        [rNext cNext] = ind2sub(CONSTANTS.imageSize, hulls(nextCells(i)).indexPixels);

        isect = intersect(hulls(updateCell).indexPixels, hulls(nextCells(i)).indexPixels);
        if ( ~isempty(isect) )
            isectDist = 1 - (length(isect) / min(length(hulls(updateCell).indexPixels), length(hulls(nextCells(i)).indexPixels)));
            connDist = setDistance(updateCell, nextCells(i), isectDist, tNext-t, connDist);
            continue;
        end
        ccMinDistSq = Inf;
        for k=1:length(r)
            ccDistSq = (rNext-r(k)).^2 + (cNext-c(k)).^2;
            ccRowMin = min(ccDistSq);
            if ( ccRowMin < ccMinDistSq )
                ccMinDistSq = ccRowMin;
            end
            
            if ( ccRowMin < 1 )
                break;
            end
        end
        
        if ( abs(tNext-t) == 1 )
            ccMaxDist = CONSTANTS.dMaxConnectComponent;
        else
            ccMaxDist = 1.5*CONSTANTS.dMaxConnectComponent;
        end
        
        if ( ccMinDistSq > (ccMaxDist^2) )
            continue;
        end
        
        connDist = setDistance(updateCell, nextCells(i), sqrt(ccMinDistSq), tNext-t, connDist);
    end
end

function connDist = setDistance(updateCell, nextCell, dist, updateDir, connDist)
    if ( updateDir > 0 )
        connDist{updateCell} = [connDist{updateCell}; nextCell dist];
        
        % Sort hulls to match MEX code
        [sortHulls sortIdx] = sort(connDist{updateCell}(:,1));
        connDist{updateCell} = connDist{updateCell}(sortIdx,:);
    else
        chgIdx = [];
        if ( ~isempty(connDist{nextCell}) )
            chgIdx = find(connDist{nextCell}(:,1) == updateCell, 1, 'first');
        end
        
        if ( isempty(chgIdx) )
            connDist{nextCell} = [connDist{nextCell}; updateCell dist];
        else
            connDist{nextCell}(chgIdx,:) = [updateCell dist];
        end
        
        % Sort hulls to match MEX code
        [sortHulls sortIdx] = sort(connDist{nextCell}(:,1));
        connDist{nextCell} = connDist{nextCell}(sortIdx,:);
    end
end

function costMatrix = getTempCosts(t, checkHulls, tempHulls)
    global CellHulls HashedCells CellTracks
    
    bValidFrom = ([CellHulls(checkHulls).time] == t);
    
    hash = HashedCells;
    
    hulls = [CellHulls tempHulls];
    hullIDs = (length(CellHulls)+1):length(hulls);
    for i=1:length(tempHulls)
        hash{t+1} = [hash{t+1} struct('hullID',{hullIDs(i)}, 'trackID',{0})];
    end
    
    connDist = updateTempConnDist(hullIDs, hulls, hash);
    
    avoidHulls = [HashedCells{t+1}.hullID];
    [costs fromHulls toHulls] = Tracker.GetTrackingCosts(4, t, t+1, unique(checkHulls(bValidFrom)), avoidHulls, hulls, hash, CellTracks, connDist);
    
    costs(costs == 0) = Inf;
    [bFromHulls checkIdx] = ismember(checkHulls, fromHulls);
    [bToHulls nextIdx] = ismember(hullIDs, toHulls);
    
    checkIdx(checkIdx==0) = size(costs,1)+1;
    nextIdx(nextIdx==0) = size(costs,2)+1;
    
    augCosts = [costs; Inf*ones(1,size(costs,2))];
    costMatrix = augCosts(checkIdx,:);
    
    augCosts = [costMatrix Inf*ones(size(costMatrix,1),1)];
    costMatrix = augCosts(:,nextIdx);
end

function costMatrix = getNextCosts(t, checkHulls, nextHulls)
    global CellHulls HashedCells CellTracks ConnectedDist
    
    bValidFrom = ([CellHulls(checkHulls).time] == t);
    bValidTo = ([CellHulls(nextHulls).time] == t+1);
    
    avoidHulls = setdiff([HashedCells{t+1}.hullID], nextHulls(bValidTo));
    [costs fromHulls toHulls] = Tracker.GetTrackingCosts(4, t, t+1, unique(checkHulls(bValidFrom)), avoidHulls, CellHulls, HashedCells, CellTracks, ConnectedDist);
    
    costs(costs == 0) = Inf;
    [bFromHulls checkIdx] = ismember(checkHulls, fromHulls);
    [bToHulls nextIdx] = ismember(nextHulls, toHulls);
    
    checkIdx(checkIdx==0) = size(costs,1)+1;
    nextIdx(nextIdx==0) = size(costs,2)+1;
    
    augCosts = [costs; Inf*ones(1,size(costs,2))];
    costMatrix = augCosts(checkIdx,:);
    
    augCosts = [costMatrix Inf*ones(size(costMatrix,1),1)];
    costMatrix = augCosts(:,nextIdx);
end

function trackEdge = getTrackInEdge(t, trackID)
    global CellTracks
    
    trackEdge = [];
    
    if ( CellTracks(trackID).startTime > t || CellTracks(trackID).endTime < t )
        return;
    end
    
    prevHull = Helper.GetNearestTrackHull(trackID, t-1, -1);
    nextHull = Helper.GetNearestTrackHull(trackID, t, 1);
    
    if ( prevHull == 0 )
        parentTrack = CellTracks(trackID).parentTrack;
        if ( isempty(parentTrack) )
            return
        end
        
        prevHull = CellTracks(parentTrack).hulls(end);
    end
    
    if ( nextHull == 0 )
        return;
    end
    
    trackEdge = [prevHull nextHull];
end


