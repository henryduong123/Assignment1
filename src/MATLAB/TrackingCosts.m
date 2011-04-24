function [costMatrix, trackedHulls, nextHulls] = TrackingCosts(trackHulls, t, avoidHulls, hulls, hash)
    windowSize = 4;

    if ( t+1 > length(hash) )
        return;
    end
    
    if ( isempty(trackHulls) )
        error('Unable to track from empty source cell list');
    end
    
    nextFrameHulls = [hash{t+1}.hullID];
    if ( isempty(nextFrameHulls) )
        error('Unable to track to empty destination cell list');
    end
    
    [trackedHulls,rowIdx] = unique(trackHulls,'first');
    [nextHulls,colIdx] = setdiff(nextFrameHulls, avoidHulls);
    
    if ( length(trackedHulls) < length(trackHulls) )
        warning('mexMAT:nonuniqueTrackingList','Non-unique track list, cost matrix will include only unique entries.');
    end
    
    if ( isempty(nextHulls) )
        error('Avoidance constraints caused empty cell list');
    end
    
    constraints = cell(1,windowSize);
    constraints{1} = trackedHulls;
    constraints{2} = nextHulls;
    for i=2:min(windowSize-1, (length(hash)-t))
        constraints{i+1} = setdiff([hash{t+i}.hullID], avoidHulls);
    end
    
    costMatrix = mexMAT(t, windowSize, constraints, hulls, hash);
    
    [dump,backRowIdx] = sort(rowIdx);
    [dump,backColIdx] = sort(colIdx);
    
    costMatrix = costMatrix(backRowIdx,backColIdx);
    trackedHulls = trackedHulls(backRowIdx);
    nextHulls = nextHulls(backColIdx);
end