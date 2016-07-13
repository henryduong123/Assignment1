% [newHulls newFamilies] = SetCellHullEntries(setIDs, setObjs, newFeat)
% Resets the CellHulls fields for cell IDs listed in setHull using the
% setObj structure list. If an entry in setHullIDs is zero then a new hull
% entry will be added with associated family/track structures.
%
% NOTE: This does not automatically update tracking information for hulls

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
%     Copyright 2016 Drexel University
%
%     This file is part of LEVer - the tool for stem cell lineaging. See
%     http://n2t.net/ark:/87918/d9rp4t for details
% 
%     LEVer is free software: you can redistribute it and/or modify
%     it under the terms of the GNU General Public License as published by
%     the Free Software Foundation, either version 3 of the License, or
%     (at your option) any later version.
% 
%     LEVer is distributed in the hope that it will be useful,
%     but WITHOUT ANY WARRANTY; without even the implied warranty of
%     MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
%     GNU General Public License for more details.
% 
%     You should have received a copy of the GNU General Public License
%     along with LEVer in file "gnu gpl v3.txt".  If not, see 
%     <http://www.gnu.org/licenses/>.
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


function [newHulls newFamilies] = SetCellHullEntries(setHullIDs, setObjs)
    global CellHulls Costs GraphEdits ResegLinks CachedCostMatrix
    
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
        
        CellHulls(hullID) = Helper.MakeInitStruct(CellHulls, setObjs(i));
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
        ResegLinks = [ResegLinks zeros(size(ResegLinks,1),addCosts); zeros(addCosts,size(ResegLinks,1)+addCosts)];
        CachedCostMatrix = [CachedCostMatrix zeros(size(CachedCostMatrix,1),addCosts); zeros(addCosts,size(CachedCostMatrix,1)+addCosts)];
    end
    
end

