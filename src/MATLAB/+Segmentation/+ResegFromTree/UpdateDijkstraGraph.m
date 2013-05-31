function UpdateDijkstraGraph(t)
    global HashedCells
    
    if ( t < 1 || t+1 > length(HashedCells) )
        return;
    end
    
    updateHulls = [HashedCells{t}.hullID];
    nextHulls = [HashedCells{t+1}.hullID];

    costMatrix = Segmentation.ResegFromTree.GetNextCosts(t, updateHulls, nextHulls);
    if ( isempty(costMatrix) )
        return;
    end
    
    mexDijkstra('updateGraph', costMatrix, updateHulls, nextHulls);
end