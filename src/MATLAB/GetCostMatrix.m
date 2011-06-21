function costMatrix = GetCostMatrix()
    global Costs GraphEdits
    
    costMatrix = Costs;
    bRemovedEdges = (GraphEdits < 0);
    costMatrix(bRemovedEdges) = 0;
    
    bSetEdges = (GraphEdits > 0);
    bSetRows = any(bSetEdges, 2);
    bSetCols = any(bSetEdges, 1);
    
    costMatrix(bSetRows,:) = 0;
    costMatrix(:,bSetCols) = 0;
    costMatrix(bSetEdges) = GraphEdits(bSetEdges)*eps;
end