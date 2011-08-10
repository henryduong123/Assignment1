function costMatrix = GetCostMatrix()
    global Costs GraphEdits
    
    costMatrix = Costs;
%     bRemovedEdges = (GraphEdits < 0);
%     costMatrix(bRemovedEdges) = 0;
%     
%     bSetEdges = (GraphEdits > 0);
%     bSetRows = any(bSetEdges, 2);
%     bSetCols = any(bSetEdges, 1);
%     
%     costMatrix(bSetRows,:) = 0;
%     costMatrix(:,bSetCols) = 0;
%     costMatrix(bSetEdges) = GraphEdits(bSetEdges)*eps;
    
    % Vectorized/binary indexed implementation of this code is commented 
    % out above because we cannot use more than 46K square elements in a 
    % matrix in 32-bit matlab.
    [r,c] = find(GraphEdits < 0);
    for i=1:length(r)
        costMatrix(r(i),c(i)) = 0;
    end
    
    [r,c] = find(GraphEdits > 0);
    for i=1:length(r)
        costMatrix(r(i),:) = 0;
        costMatrix(:,c(i)) = 0;
    end
    for i=1:length(r)
        costMatrix(r(i),c(i)) = GraphEdits(r(i),c(i))*eps;
    end
end