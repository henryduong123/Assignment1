% InitializeCachedCosts()
% Initialize CachedCostMatrix from current Costs and GraphEdits

function InitializeCachedCosts(bForceInitialize)
    global Costs GraphEdits CellHulls CachedCostMatrix
    
    if ( ~bForceInitialize && (size(CachedCostMatrix,1) == size(Costs,1)) )
        return;
    end
    
    CachedCostMatrix = Costs;
    % bRemovedEdges = (GraphEdits < 0);
    % costMatrix(bRemovedEdges) = 0;
    %
    % bSetEdges = (GraphEdits > 0);
    % bSetRows = any(bSetEdges, 2);
    % bSetCols = any(bSetEdges, 1);
    %
    % costMatrix(bSetRows,:) = 0;
    % costMatrix(:,bSetCols) = 0;
    % costMatrix(bSetEdges) = GraphEdits(bSetEdges)*eps;
    
    % Vectorized/binary indexed implementation of this code is commented 
    % out above because we cannot use more than 46K square elements in a 
    % matrix in 32-bit matlab.
    [r,c] = find(GraphEdits < 0);
    for i=1:length(r)
        CachedCostMatrix(r(i),c(i)) = 0;
    end
    
    % Remove all edges to/from deleted hulls
    % This may end up being super slow, however it stops other graph code
    % from always having to check for deleted hulls (in general) by making
    % them unreachable.
    r = find([CellHulls.deleted]);
    for i=1:length(r)
        CachedCostMatrix(r(i),:) = 0;
        CachedCostMatrix(:,r(i)) = 0;
    end
    
    [r,c] = find(GraphEdits > 0);
    for i=1:length(r)
        CachedCostMatrix(r(i),:) = 0;
        CachedCostMatrix(:,c(i)) = 0;
    end
    for i=1:length(r)
        CachedCostMatrix(r(i),c(i)) = eps * GraphEdits(r(i),c(i));
    end
end

