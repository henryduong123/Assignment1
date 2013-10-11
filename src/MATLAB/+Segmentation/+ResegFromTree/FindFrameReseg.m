function newEdges = FindFrameReseg(t, curEdges, bIgnoreEdges)
    global CellHulls HashedCells ResegState
    
    newEdges = zeros(0,2);
    curEdges = curEdges(~bIgnoreEdges,:);
    
    if ( isempty(curEdges) )
        return;
    end
    
    tFrom = [CellHulls(curEdges(:,1)).time];
    
    bLongEdge = ((t-tFrom) > 1);
    
    % bReallyLongEdge determines when we stop looking for hulls for this
    % track.
    bReallyLongEdge = ((t-tFrom) > 5);
    checkEdges = curEdges(~bReallyLongEdge,:);
    bLongEdge = bLongEdge(~bReallyLongEdge);
    
    [checkHulls uniqueIdx] = unique(checkEdges(:,1));
    nextHulls = [HashedCells{t}.hullID];
    
    % Find mitosis edges
    mitIdx = setdiff(1:size(checkEdges,1), uniqueIdx);
    mitosisParents = checkEdges(mitIdx,1);
    
    costMatrix = Segmentation.ResegFromTree.GetNextCosts(t-1, checkHulls, nextHulls);
    
    % TODO: Do I need to handle erroneous missed mitoses?
    % Get costs for existing hulls in frame t back more than t-1 for
    % tracks without hulls in t-1,...
    missIdx = find(bLongEdge(uniqueIdx));
    for i=1:length(missIdx)
        extendHull = checkHulls(missIdx(i));
        maxExt = t - CellHulls(extendHull).time + 1;
        
        [endpaths endCosts] = mexDijkstra('matlabExtend', extendHull, maxExt, @(x,y)(any(y==nextHulls)), 1, 0);
        lastHulls = cellfun(@(x)(x(end)), endpaths);
        [bFoundPath arrIdx] = ismember(nextHulls, lastHulls);
        
        costMatrix(missIdx(i),bFoundPath) = endCosts(arrIdx(bFoundPath));
    end

    % Force-keep mitosis edges
    % TODO: handle this better in the case of a not completely edited tree.
    for i=1:length(mitosisParents)
        mitChkIdx = find(checkHulls == mitosisParents(i),1,'first');
        childHulls = checkEdges((checkEdges(:,1) == mitosisParents(i)), 2);
        
        [bFoundHulls childIdx] = ismember(childHulls, nextHulls);
        if ( ~all(bFoundHulls) )
            error(['Malformed mitosis event in frame ' num2str(t)]);
        end

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
        
        % Old guys can't add
        if ( any(i == missIdx) )
            continue
        end
        
        overlapDist = Segmentation.ResegFromTree.GetLongOverlapDist(checkHulls(i), nextHulls);
        minOverlap = min(overlapDist);
        
        if ( minOverlap < 2.0 )
            continue;
        end
        
        [addedHull costMatrix nextHulls] = Segmentation.ResegFromTree.AddSegmentation(checkHulls(i), costMatrix, checkHulls, nextHulls);
        if ( isempty(addedHull) )
            if ( ~all(isinf(costMatrix(i,:))) )
                continue;
            end

            [addedHull costMatrix nextHulls] = Segmentation.ResegFromTree.AddSegmentation(checkHulls(i), costMatrix, checkHulls, nextHulls, 1);

            if ( isempty(addedHull) )
                continue;
            end
        end

        ResegState.SegEdits = [ResegState.SegEdits;{0} {addedHull}];

        bAddedHull(i) = 1;
    end
    
    % Find hulls we may need to split
    desiredCellCount = zeros(length(nextHulls),1);
    desirers = cell(length(nextHulls),1);
    for i=1:length(checkHulls)
        [desiredCosts desiredIdx] = sort(costMatrix(i,:));
        if ( isinf(desiredCosts(1)) )
            continue;
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
        validSplitCount = 0;
        validDesirers = [];
        
        % Only allow splits if cells are really close together
        chkDist = zeros(desiredCellCount(splitIdx(i)),1);
        for j=1:desiredCellCount(splitIdx(i))
            chkDist(j) = Segmentation.ResegFromTree.GetLongOverlapDist(desirers{splitIdx(i)}(j), nextHulls(splitIdx(i)));
            bIsMitParent = any(desirers{splitIdx(i)}(j) == mitosisParents);
            if ( chkDist(j) < 2.0 || bIsMitParent )
                validSplitCount = validSplitCount + 1;
                validDesirers = [validDesirers desirers{splitIdx(i)}(j)];
            end
        end
        
        if ( isempty(validDesirers) )
            continue;
        end
        
        [newSegs costMatrix nextHulls] = Segmentation.ResegFromTree.SplitSegmentation(nextHulls(splitIdx(i)), validSplitCount, validDesirers, mitosisParents, costMatrix, checkHulls, nextHulls);
        if ( length(newSegs) > 1 )
            ResegState.SegEdits = [ResegState.SegEdits;{nextHulls(splitIdx(i))} {newSegs}];
        end
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
    
    % Return newEdges in same order as curEdges
    [sortedNew, srtNewIdx] = sort(newEdges(:,1));
    [sortedOld, srtOldIdx] = sort(curEdges(:,1));
    if ( sortedNew ~= sortedOld )
        error('Unmatched edge in newEdges list');
    end
    
    newEdges(srtOldIdx,:) = newEdges(srtNewIdx,:);
    
end
