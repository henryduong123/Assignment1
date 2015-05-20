function UpdateFrozenCosts(treeID, bFrozen)
    global CellFamilies CellTracks CachedCostMatrix
    
    if ( ~bFrozen )
        % Reset previous frozen hulls
        bFrozenFam = ([CellFamilies.bFrozen]);
        frozenTracks = [CellFamilies(bFrozenFam).tracks];
        chkHulls = [CellTracks(frozenTracks).hulls];
        
        frozenHulls = chkHulls(chkHulls>0);
        
        Tracker.UpdateCachedCosts(frozenHulls,frozenHulls);
    else
        % Update cached costs so that there's only one option for frozen
        % hull edges
        edges = [];
        famTracks = CellFamilies(treeID).tracks;
        for i=1:length(famTracks)
            chkHulls = CellTracks(famTracks(i)).hulls;
            trackHulls = chkHulls(chkHulls > 0);

            trackEdges = [trackHulls(1:end-1); trackHulls(2:end); ones(1,length(trackHulls)-1)].';

            childTracks = CellTracks(famTracks(i)).childrenTracks;
            if ( ~isempty(childTracks) )
                childHull = CellTracks(childTracks(1)).hulls(1);
                siblingHull = CellTracks(childTracks(2)).hulls(1);

                trackEdges = [trackEdges; trackHulls(end) childHull 1];
                trackEdges = [trackEdges; trackHulls(end) siblingHull 2];
            end

            edges = [edges; trackEdges];
        end

        CachedCostMatrix(edges(:,1),:) = 0;
        CachedCostMatrix(:,edges(:,2)) = 0;

        for i=1:size(edges,1)
            CachedCostMatrix(edges(i,1),edges(i,2)) = edges(i,3);
        end
    end
end