% UpdateCostEdges(costMatrix, fromHulls, toHulls)
% Updates full Cost graph with edges from the costMatrix subgraph.
% Also handles updating the cached matrix used by GetCostMatrix() calls.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
%     Copyright 2011-2016 Andrew Cohen
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

