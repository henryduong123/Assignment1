% [newHulls newFamilies] = SetHullEntries(setIDs, setObjs, newFeat)
% Resets the CellHulls fields for cell IDs listed in setHull using the
% setObj structure list. If an entry in setHullIDs is zero then a new hull
% entry will be added with associated family/track structures.
%
% NOTE: This does not automatically update tracking information for hulls

function [newHulls newFamilies] = SetHullEntries(setHullIDs, setObjs)
    global CellHulls Costs GraphEdits CachedCostMatrix
    
    newHulls = [];
    newFamilies = [];
    
    if ( isempty(setHullIDs) )
        return;
    end
    
    if ( length(setHullIDs) ~= length(setObjs) )
        error('List of hull IDs is not the same size as the list of structure entries.');
    end
    
    for i=1:length(setHullIDs)
        hullID = setHullIDs(i);
        if ( hullID == 0 )
            hullID = length(CellHulls) + 1;
        end
        
        CellHulls(hullID).time = setObjs(i).time;
        CellHulls(hullID).points = setObjs(i).points;
        CellHulls(hullID).indexPixels = setObjs(i).indexPixels;
        CellHulls(hullID).imagePixels = setObjs(i).imagePixels;
        CellHulls(hullID).centerOfMass = setObjs(i).centerOfMass;
        CellHulls(hullID).deleted = setObjs(i).deleted;
        CellHulls(hullID).userEdited = setObjs(i).userEdited;
        
        newHulls = [newHulls hullID];
        
        if ( setHullIDs(i) > 0 )
            continue;
        end
        
        % If this is a new cell create associated family/tracks
        newFamilies = [newFamilies Families.NewCellFamily(hullID)];
    end
    
    % Recalculate connected-component distances for updated CellHulls entries
    Tracker.BuildConnectedDistance(newHulls, 1);
    
    % Add zero Costs/GraphEdits/CachedCostMatrix for new
    addCosts = max(newHulls)-size(Costs,1);
    if (  addCosts > 0 )
        Costs = [Costs zeros(size(Costs,1),addCosts); zeros(addCosts,size(Costs,1)+addCosts)];
        GraphEdits = [GraphEdits zeros(size(GraphEdits,1),addCosts); zeros(addCosts,size(GraphEdits,1)+addCosts)];
        CachedCostMatrix = [CachedCostMatrix zeros(size(CachedCostMatrix,1),addCosts); zeros(addCosts,size(CachedCostMatrix,1)+addCosts)];
    end
    
end

