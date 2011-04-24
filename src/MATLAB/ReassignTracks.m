function changedHulls = ReassignTracks(t, costMatrix, extendHulls, affectedHulls, changedHulls)
    if ( ~exist('changedHulls','var') )
        changedHulls = [];
    end
    
    [minInCosts,bestIncoming] = min(costMatrix,[],1);
    [minOutCosts,bestOutgoing] = min(costMatrix,[],2);
    
    bestOutgoing  = bestOutgoing';
    bMatchedCol = false(size(bestIncoming));
    bMatched = (bestIncoming(bestOutgoing) == (1:length(bestOutgoing)));
    bMatchedCol(bestOutgoing(bMatched)) = 1;
    matchedIdx = find(bMatched);
    
    % Assign matched edges
	for i=1:length(matchedIdx)
        assignHull = affectedHulls(bestOutgoing(matchedIdx(i)));
        % Note: It is very important to get track IDs inside the loop as they
        % are not invariant due to possible tree relationship changes cause
        % by hull/track removal
        assignTrack = GetTrackID(extendHulls(matchedIdx(i)));
        
        change = assignHullToTrack(t, assignHull, assignTrack);
        changedHulls = [changedHulls change];
	end
    
    costMatrix(bMatched,:) = Inf;
    costMatrix(:,bMatchedCol) = Inf;
    
    [minCost minIdx] = min(costMatrix(:));
    
    % Patch up whatever other nurtureTracks we can
    while ( minCost ~= Inf )
        [r c] = ind2sub(size(costMatrix), minIdx);
        assignHull = affectedHulls(c);
        assignTrack = GetTrackID(extendHulls(r));
        
        change = assignHullToTrack(t, assignHull, assignTrack);
        changedHulls = [changedHulls change];
        
        costMatrix(r,:) = Inf;
        costMatrix(:,c) = Inf;
        
        [minCost minIdx] = min(costMatrix(:));
    end
    
    changedHulls = unique(changedHulls);
end

function changedHulls = assignHullToTrack(t, hull, track)
    global HashedCells
    
    oldHull = [];
    changedHulls = [];
    
	% Get old hull - track assignments
    bOldHull = [HashedCells{t}.trackID] == track;
    if ( any(bOldHull) )
        oldHull = HashedCells{t}(bOldHull).hullID;
    end
    
    oldTrack = HashedCells{t}([HashedCells{t}.hullID] == hull).trackID;

    % Hull - track assignment is unchanged
    if ( oldHull == hull )
        return;
    end

    if ( ~isempty(oldHull) )
        % Swap track assignments
        swapTracking(t, oldHull, hull, track, oldTrack);
        changedHulls = [oldHull hull];
    else
        % Add hull to track
        %ChangeLabel(t, oldTrack, track);
        RemoveHullFromTrack(hull, oldTrack, 1);
        ExtendTrackWithHull(track, hull);
        changedHulls = hull;
    end
end

% Currently hullA has trackA, hullB has trackB
% swap so that hullA gets trackB and hullB gets trackA
function swapTracking(t, hullA, hullB, trackA, trackB)
    global HashedCells CellTracks
    
    hashAIdx = ([HashedCells{t}.hullID] == hullA);
    hashBIdx = ([HashedCells{t}.hullID] == hullB);
    
    % Swap track IDs
    HashedCells{t}(hashAIdx).trackID = trackB;
    HashedCells{t}(hashBIdx).trackID = trackA;
    
    % Swap hulls in tracks
    hashTime = t - CellTracks(trackA).startTime + 1;
    CellTracks(trackA).hulls(hashTime) = hullB;
    
    hashTime = t - CellTracks(trackB).startTime + 1;
    CellTracks(trackB).hulls(hashTime) = hullA;
end