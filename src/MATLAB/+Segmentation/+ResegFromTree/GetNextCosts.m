function costMatrix = GetNextCosts(t, checkHulls, nextHulls)
    global CellHulls HashedCells CellTracks ConnectedDist
    
    bValidFrom = ([CellHulls(checkHulls).time] == t);
    bValidTo = ([CellHulls(nextHulls).time] == t+1);
    
    currentHulls = unique(checkHulls(bValidFrom));
    
    if ( isempty(currentHulls) )
        costMatrix = Inf*ones(length(checkHulls),length(nextHulls));
        return;
    end
    
    avoidHulls = setdiff([HashedCells{t+1}.hullID], nextHulls(bValidTo));
    [costs fromHulls toHulls] = Tracker.GetTrackingCosts(4, t, t+1, currentHulls, avoidHulls, CellHulls, HashedCells, CellTracks, ConnectedDist);
    
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
