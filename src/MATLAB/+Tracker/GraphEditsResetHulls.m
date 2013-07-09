% GraphEditsResetHulls(hulls, bResetForward, bResetBack)
% 
% Clears all user edits into (bResetBack) and/or out of (bResetForward)
% a hull, updates associated cached costs.

function GraphEditsResetHulls(hulls, bResetForward, bResetBack)
    global Costs GraphEdits
    
    if ( ~exist('bResetForward','var') )
        bResetForward = 1;
    end
    
    if ( ~exist('bResetBack','var') )
        bResetBack = 1;
    end
    
    toHulls = hulls;
    fromHulls = hulls;
    
    if ( ~bResetForward && ~bResetBack )
        return;
    end
    
    for i=1:length(hulls)
        toHulls = union(toHulls, find((Costs(hulls(i),:) > 0) | (GraphEdits(hulls(i),:) > 0)));
        fromHulls = union(fromHulls, find((Costs(:,hulls(i)) > 0) | (GraphEdits(:,hulls(i)) > 0)));
    end
    
    if ( bResetForward )
        for i=1:length(hulls)
            GraphEdits(hulls(i),:) = 0;
        end
    end
    
    if ( bResetBack )
        for i=1:length(hulls)
            GraphEdits(:,hulls(i)) = 0;
        end
    end
    
    Tracker.UpdateCachedCosts(fromHulls, toHulls);
end
