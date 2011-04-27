function [deleteCells replaceCell] = MergeSplitCells(clickPt)
    global Figures CellHulls HashedCells SegmentationEdits
    
    replaceCell = [];
    
    t = Figures.time;
    [mergeObj, deleteCells] = FindMergedCell(t, clickPt);
    
    if ( isempty(mergeObj) || isempty(deleteCells) )
        return;
    end
    
    replaceCell = min(deleteCells);
    deleteCells = setdiff(deleteCells,replaceCell);
    
    for i=1:length(deleteCells)
        RemoveHull(deleteCells(i));
    end
    
    CellHulls(replaceCell).points = mergeObj.points;
    CellHulls(replaceCell).indexPixels = mergeObj.indexPixels;
    CellHulls(replaceCell).imagePixels = mergeObj.imagePixels;
    CellHulls(replaceCell).centerOfMass = mergeObj.centerOfMass;
    CellHulls(replaceCell).deleted = 0;
    
    [costMatrix, extendHulls, affectedHulls] = TrackThroughMerge(t, replaceCell);
    if ( isempty(costMatrix) )
        return;
    end
    
    changedHulls = ReassignTracks(t, costMatrix, extendHulls, affectedHulls, replaceCell);
    
    t = propagateMerge(replaceCell, changedHulls);

    if ( t < length(HashedCells) )
        checkHulls = [HashedCells{t}.hullID];
        nextHulls = [HashedCells{t+1}.hullID];
        
        [costMatrix bExtendHulls bAffectedHulls] = GetCostSubmatrix(checkHulls, nextHulls);
        extendHulls = checkHulls(bExtendHulls);
        affectedHulls = nextHulls(bAffectedHulls);
        
        ReassignTracks(t+1, costMatrix, extendHulls, affectedHulls, [], 1);
    end
    
    SegmentationEdits.newHulls = [];
    SegmentationEdits.changedHulls = [];
    UpdateSegmentationEditsMenu();
end

function tLast = propagateMerge(mergedHull, trackHulls)
    global CellHulls HashedCells

    tStart = CellHulls(mergedHull).time;
    tEnd = length(HashedCells)-1;
    
    tLast = tStart;
    for t=tStart:tEnd
        if ( isempty(mergedHull) )
            return;
        end
        
        checkHulls = [HashedCells{t}.hullID];
        nextHulls = [HashedCells{t+1}.hullID];

        UpdateTrackingCosts(t, trackHulls, nextHulls);
        
        [costMatrix, bExtendHulls, bAffectedHulls] = GetCostSubmatrix(checkHulls, nextHulls);
        extendHulls = checkHulls(bExtendHulls);
        affectedHulls = nextHulls(bAffectedHulls);
        
        bMhIdx = (extendHulls == mergedHull);
        [mincost,mergeIdx] = min(costMatrix(bMhIdx,:));
        
        if ( isempty(mincost) || isinf(mincost) )
            return;
        end
        
        checkPt = CellHulls(affectedHulls(mergeIdx)).centerOfMass;
        [mergeObj, deleteCells] = FindMergedCell(t+1, [checkPt(2) checkPt(1)]);
        
        if ( isempty(mergeObj) || isempty(deleteCells) )
            return;
        end
        
        [trackHulls mergedHull] = checkMergeHulls(t+1, costMatrix, extendHulls, affectedHulls, mergedHull, deleteCells);
        tLast = t;
    end
end

function [changedHulls replaceIdx] = checkMergeHulls(t, costMatrix, checkHulls, nextHulls, mergedHull, deleteHulls)
    global CONSTANTS CellHulls HashedCells
    
    mergedIdx = find(checkHulls == mergedHull);
    bDeleteHulls = ismember(nextHulls, deleteHulls);
    [minIn,bestIn] = min(costMatrix,[],1);
    
    deleteHulls = nextHulls(bDeleteHulls);
    nextMergeHulls = deleteHulls(bestIn(bDeleteHulls) == mergedIdx);
    
    changedHulls = [];
    replaceIdx = [];
    
    if ( length(nextMergeHulls) <= 1 )
        return;
    end
    
    replaceIdx = min(nextMergeHulls);
    deleteCells = setdiff(nextMergeHulls, replaceIdx);
    
    CellHulls(replaceIdx).indexPixels = vertcat(CellHulls(nextMergeHulls).indexPixels);
    CellHulls(replaceIdx).imagePixels = vertcat(CellHulls(nextMergeHulls).imagePixels);
    
    [r c] = ind2sub(CONSTANTS.imageSize, CellHulls(replaceIdx).indexPixels);
    chIdx = convhull(c,r);
    
    CellHulls(replaceIdx).points = [c(chIdx) r(chIdx)];
    CellHulls(replaceIdx).centerOfMass = mean([r c]);
    CellHulls(replaceIdx).deleted = 0;
    
    for i=1:length(deleteCells)
        RemoveHull(deleteCells(i));
    end
    
    [costMatrix extendHulls affectedHulls] = TrackThroughMerge(t, replaceIdx);
    if ( isempty(costMatrix) )
        return;
    end
    
    nextHulls = [HashedCells{t}.hullID];
    
    [costMatrix bExtendHulls bAffectedHulls] = GetCostSubmatrix(checkHulls, nextHulls);
    extendHulls = checkHulls(bExtendHulls);
    affectedHulls = nextHulls(bAffectedHulls);
    
    changedHulls = ReassignTracks(t, costMatrix, extendHulls, affectedHulls, replaceIdx);
end

