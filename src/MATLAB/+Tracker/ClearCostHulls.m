% ClearCostEdges(hulls)
% Zeros all incoming and outgoing edges from hulls in Costs graph, also
% updates GraphEdits and cached cost matrix.

function ClearCostHulls(hulls)
    global Costs GraphEdits CachedCostMatrix
    
    for i=1:length(hulls)
        Costs(hulls(i),:) = 0;
        CachedCostMatrix(hulls(i),:) = 0;
        GraphEdits(hulls(i),:) = 0;
        
        Costs(:,hulls(i)) = 0;
        CachedCostMatrix(:,hulls(i)) = 0;
        GraphEdits(:,hulls(i)) = 0;
    end
end

