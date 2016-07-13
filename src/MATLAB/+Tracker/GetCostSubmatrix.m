% GetCostSubmatrix.m - Get submatrix from sparse cost matrix at the given
% from and to hullIDs

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

function [costMatrix bFromAffected bToAffected] = GetCostSubmatrix(fromHulls, toHulls)
    inCostMatrix = Tracker.GetCostMatrix();
    
    % Get costMatrix representing costs from fromHulls to toHulls
    %[r c] = ndgrid(fromHulls, toHulls);
    %costIdx = sub2ind(size(inCostMatrix), r, c);
    %costMatrix = full(inCostMatrix(costIdx));
    
    % Vectorized implementation of this code is commented out above
    % because we cannot use more than 46K square elements in a matrix in
    % 32-bit matlab.
    costMatrix = zeros(length(fromHulls),length(toHulls));
    for j=1:length(toHulls)
        costMatrix(:,j) = inCostMatrix(fromHulls, toHulls(j));
    end

    bToAffected = any(costMatrix,1);
    costMatrix = costMatrix(:,bToAffected);
    
    bFromAffected = any(costMatrix,2);
    costMatrix = full(costMatrix(bFromAffected,:));

    costMatrix(costMatrix == 0) = Inf;
end
