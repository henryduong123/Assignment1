% GraphEditsResetHulls(hulls)
% Resets (zeros) all user edits into and out of a hull, updates associated
% cached costs.

function GraphEditsResetHulls(hulls)
    global Costs GraphEdits
    
    toHulls = hulls;
    fromHulls = hulls;
    
    for i=1:length(hulls)
        GraphEdits(hulls(i),:) = 0;
        GraphEdits(:,hulls(i)) = 0;
        
        toHulls = union(toHulls, find(Costs(hulls(i),:) > 0));
        fromHulls = union(fromHulls, find(Costs(:,hulls(i)) > 0));
    end
    
    Tracker.UpdateCachedCosts(fromHulls, toHulls);
end
