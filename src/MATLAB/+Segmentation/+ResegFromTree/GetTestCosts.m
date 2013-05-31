function costMatrix = GetTestCosts(t, checkHulls, tempHulls)
    global CellHulls HashedCells CellTracks
    
    bValidFrom = ([CellHulls(checkHulls).time] == t);
    
    hash = HashedCells;
    
    hulls = [CellHulls tempHulls];
    hullIDs = (length(CellHulls)+1):length(hulls);
    for i=1:length(tempHulls)
        hash{t+1} = [hash{t+1} struct('hullID',{hullIDs(i)}, 'trackID',{0})];
    end
    
    connDist = Segmentation.ResegFromTree.UpdateConnDistance(hullIDs, hulls, hash);
    
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