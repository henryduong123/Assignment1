function trackIDs = TrackSplitHulls(newHulls, forceTracks, COM)
    global CONSTANTS CellHulls HashedCells Costs
    
    % Update incoming and outgoing connected-component distance for new hulls
    BuildConnectedDistance(newHulls, 1);
    
    % Add zero costs to cost matrix if necessary
    addCosts = max(max(newHulls)-size(Costs,1),0);
    if (  addCosts > 0 )
        Costs = [Costs zeros(size(Costs,1),addCosts); zeros(addCosts,size(Costs,1)+addCosts)];
    end
    
    t = CellHulls(newHulls(1)).time;
    
    trackIDs = [];
    for i = 1:length(newHulls)
        trackIDs = [trackIDs GetTrackID(newHulls(i))];
    end
    
    if ( t <= 1 )
        return;
    end
    
    curHulls = [HashedCells{t}.hullID];
%     curTracks = [HashedCells{t}.trackID];
    lastHulls = [HashedCells{t-1}.hullID];
    distSq = sum((vertcat(CellHulls(lastHulls).centerOfMass) - ones(length(lastHulls),1)*COM).^2, 2);
    
    bTrackHull = distSq < CONSTANTS.maxRetrackDistSq;
    trackHulls = lastHulls(bTrackHull);
    
    if ( isempty(trackHulls) )
        return;
    end
    
    oldTracks = [HashedCells{t-1}(bTrackHull).trackID];
    
%     % TODO: don't muck up edited tracks (labels)
%     for i=1:length(oldTracks)
%         hashTime = t - CellTracks(oldTracks(i)).startTime + 1;
%         if ( length(CellTracks(oldTracks(i)).hulls) >= hashTime )
%             CellTracks(oldTracks(i)).hulls(hashTime) = 0;
%         end
%     end
    
    avoidHulls = setdiff(curHulls,newHulls);
    tmpGConnect = TrackingCosts(trackHulls, t-1, avoidHulls, CellHulls, HashedCells);
    
    [r c] = ndgrid(trackHulls, curHulls);
    costIdx = sub2ind(size(tmpGConnect), r, c);
    costMatrix = tmpGConnect(costIdx);
    
    bAffected = any(costMatrix,1);
    affectedHulls = curHulls(bAffected);
    costMatrix = costMatrix(:,bAffected);
    
    bOutTracked = any(costMatrix,2);
%     trackHulls = trackHulls(bOutTracked);
    extendTracks = oldTracks(bOutTracked);
    costMatrix = full(costMatrix(bOutTracked,:));
    
    costMatrix(costMatrix == 0) = Inf;
    
%     % Dump unaffected tracks from the force-keep list
%     affectedTracks = curTracks(bAffected);
%     forceTracks = intersect(forceTracks, union(oldTracks,affectedTracks));
    
    assignTracks(t, costMatrix, extendTracks, affectedHulls);
    
    trackIDs = [HashedCells{t}(ismember([HashedCells{t}.hullID],newHulls)).trackID];
end

function assignTracks(t, costMatrix, extendTracks, affectedHulls)
%     bMustAssign = ismember(oldTracks, forceTracks);
%     bDontChange = ismember(affectedTracks, setdiff(forceTracks,oldTracks));
%     
%     % Remove columns representing assignments which will remove a
%     % force-keep track
%     affectedHulls = affectedHulls(~bDontChange);
%     costMatrix = costMatrix(:,~bDontChange);
    
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
        assignTrack = extendTracks(matchedIdx(i));
        
        assignHullToTrack(t, assignHull, assignTrack);
    end
    
    costMatrix(bMatched,:) = Inf;
    costMatrix(:,bMatchedCol) = Inf;
    
    [minCost minIdx] = min(costMatrix(:));
    % Patch up whatever other tracks we can
    while( ~isinf(minCost) )
        [r c] = ind2sub(size(costMatrix), minIdx);
        assignHull = affectedHulls(c);
        assignTrack = extendTracks(r);
        
        assignHullToTrack(t, assignHull, assignTrack);
        
        costMatrix(r,:) = Inf;
        costMatrix(:,c) = Inf;
        
        [minCost minIdx] = min(costMatrix(:));
    end
end

function assignHullToTrack(t, hull, track)
    global HashedCells
    
    oldHull = [];
    
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
    else
        % Add hull to track
        AddHullToTrack(hull, track, []);
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
