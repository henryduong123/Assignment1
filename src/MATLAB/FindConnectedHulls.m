function connectedHulls = FindConnectedHulls(hullID)
    connectedHulls = hullID;
    costMatrix = GetCostMatrix();
    
    traverseHulls = connectedHulls;
    
    while ( ~isempty(traverseHulls) )
        traverseHulls = findTraverseHulls(costMatrix, traverseHulls);
        
        traverseHulls = setdiff(traverseHulls, connectedHulls);
        connectedHulls = union(connectedHulls, traverseHulls);
    end
end

function traverseHulls = findTraverseHulls(costMatrix, connectedHulls)
    backHulls = find(any(costMatrix(:,connectedHulls),2));
    forwardHulls = find(any(costMatrix(connectedHulls,:),1));
    
    traverseHulls = union(backHulls, forwardHulls);
end