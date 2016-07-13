% InitializeCachedCosts()
% Initialize CachedCostMatrix from current Costs and GraphEdits

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


function InitializeCachedCosts(bForceInitialize)
    global Costs GraphEdits CellHulls CachedCostMatrix CellFamilies
    
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
    
    % Update cached costs for frozen tree hulls
    frozenTrees = find([CellFamilies.bFrozen] > 0);
    for i=1:length(frozenTrees)
        Helper.UpdateFrozenCosts(frozenTrees(i),true);
    end
end

