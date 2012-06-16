% UpdateCachedCosts(fromHulls, toHulls)
% This must be run after a cost matrix or graph-edits change to keep cached
% costs up to date.

function UpdateCachedCosts(fromHulls, toHulls)
    global Costs GraphEdits CachedCostMatrix
    
    % Update CachedCostMatrix
    fromMap = zeros(1,size(Costs,1));
    fromMap(fromHulls) = 1:length(fromHulls);
    
    for j=1:length(toHulls)
        setCol = Costs(fromHulls,toHulls(j));
        
        % Handle updating graph-edit related cache edges
        bAddedEdges = (GraphEdits(:,toHulls(j)) > 0);
        if ( nnz(bAddedEdges) > 0 )
            % Zero all edges but user edited ones, zero removed edges
            setCol = eps * GraphEdits(fromHulls,toHulls(j));
            setCol(setCol < 0) = 0;
        else
            % Remove costs associated with user removed edges
            rmFromEdge = fromMap(GraphEdits(:,toHulls(j)) < 0);
            rmFromEdge = rmFromEdge(rmFromEdge > 0);
            setCol(rmFromEdge) = 0;
        end
        
        CachedCostMatrix(fromHulls,toHulls(j)) = setCol;
    end
end

