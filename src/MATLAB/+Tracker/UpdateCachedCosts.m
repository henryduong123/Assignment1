% UpdateCachedCosts(fromHulls, toHulls)
% This must be run after a cost matrix or graph-edits change to keep cached
% costs up to date.

function UpdateCachedCosts(fromHulls, toHulls)
    global CellHulls Costs GraphEdits CachedCostMatrix
    
    % Add any graphedited hulls to from/to list
    toHulls = union(toHulls, find(any(GraphEdits(fromHulls,:)~=0, 1)));
    fromHulls = union(fromHulls, find(any(GraphEdits(:,toHulls)~=0, 2)));
    
    % Don't mess with deleted edges
    fromHulls = fromHulls(~[CellHulls(fromHulls).deleted]);
    toHulls = toHulls(~[CellHulls(toHulls).deleted]);
    
    % Update CachedCostMatrix
    fromMap = zeros(1,size(Costs,1));
    fromMap(fromHulls) = 1:length(fromHulls);
    
    bOtherEdges = any((GraphEdits(fromHulls,:) > 0),2);
    
    for j=1:length(toHulls)
        setCol = Costs(fromHulls,toHulls(j));
    
        % Zero edges other than added edits
        setCol(bOtherEdges) = 0;
        
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

