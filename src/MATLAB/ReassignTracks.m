%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
%     This file is part of LEVer.exe
%     (C) 2011 Andrew Cohen, Eric Wait and Mark Winter
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function changedHulls = ReassignTracks(t, costMatrix, extendHulls, affectedHulls, changedHulls, bPropForward)
    if ( ~exist('changedHulls','var') )
        changedHulls = [];
    end
    
    if ( ~exist('bPropForward','var') )
        bPropForward = 0;
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
        extHull = extendHulls(matchedIdx(i));
        
        change = assignHullToTrack(t, assignHull, extHull, bPropForward);
        changedHulls = [changedHulls change];
	end
    
    costMatrix(bMatched,:) = Inf;
    costMatrix(:,bMatchedCol) = Inf;
    
    [minCost minIdx] = min(costMatrix(:));
    
    % Patch up whatever other nurtureTracks we can
    while ( minCost ~= Inf )
        [r c] = ind2sub(size(costMatrix), minIdx);
        assignHull = affectedHulls(c);
        extHull = extendHulls(r);
        
        change = assignHullToTrack(t, assignHull, extHull, bPropForward);
        changedHulls = [changedHulls change];
        
        costMatrix(r,:) = Inf;
        costMatrix(:,c) = Inf;
        
        [minCost minIdx] = min(costMatrix(:));
    end
    
    changedHulls = unique(changedHulls);
end

function changedHulls = assignHullToTrack(t, hull, extHull, bUseChangeLabel)
    global HashedCells
    
    % Get track to which we will assign hull from extHulls
    track = GetTrackID(extHull);
    
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

    if ( bUseChangeLabel )
        exchangeTrackLabels(t, oldTrack, track);
        return;
    end
    
    if ( ~isempty(oldHull) )
        % Swap track assignments
        swapTracking(t, oldHull, hull, track, oldTrack);
        changedHulls = [oldHull hull];
    else
        % Add hull to track
        RemoveHullFromTrack(hull, oldTrack, 1);
        
        % Some RemoveHullFromTracke cases cause track to be changed
        track = GetTrackID(extHull);
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

function exchangeTrackLabels(t, oldTrack, track)
    global CellTracks CellFamilies
    
    RehashCellTracks(track, CellTracks(track).startTime);
    RehashCellTracks(oldTrack, CellTracks(oldTrack).startTime);
    
    if ( CellTracks(track).endTime >= t )
        RemoveFromTree(t, track, 'no');
    end
    
    if ( CellTracks(oldTrack).startTime < t )
        newFamID = RemoveFromTree(t, oldTrack, 'no');
        removeIfEmptyTrack(oldTrack);
        
        oldTrack = CellFamilies(newFamID).rootTrackID;
    end
    
    ChangeLabel(t, oldTrack, track);
end

function removeIfEmptyTrack(track)
    global CellTracks
    
    RehashCellTracks(track);
    if ( ~isempty(CellTracks(track).hulls) )
        return;
    end
    
    childTracks = CellTracks(track).childrenTracks;
    for i=1:length(childTracks)
        RemoveFromTree(CellTracks(childTracks(i)).startTime, childTracks(i), 'no');
    end

    RemoveTrackFromFamily(track);
    ClearTrack(track);
end