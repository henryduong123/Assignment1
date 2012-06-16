% UpdateCostEdges(costMatrix, fromHulls, toHulls)
% Updates full Cost graph with edges from the costMatrix subgraph.
% Also handles updating the cached matrix used by GetCostMatrix() calls.

function UpdateCostEdges(costMatrix, fromHulls, toHulls)
    global Costs

%     [r c] = ndgrid(fromHulls, toHulls);
%     costIdx = sub2ind(size(Costs), r, c);
%     Costs(costIdx) = costMatrix;

    % Vectorized implementation of this code is commented out above
    % because we cannot use more than 46K square elements in a matrix in
    % 32-bit matlab.
    for j=1:length(toHulls)
        Costs(fromHulls,toHulls(j)) = costMatrix(:,j);
    end
    
    Tracker.UpdateCachedCosts(fromHulls, toHulls);
end

