% ClearHull( hullID )
% Clears the hull and marks it deleted

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


% ChangeLog:
% EW 6/8/12 created
function ClearHull( hullID )
global CellHulls CellPhenotypes GraphEdits ResegLinks CachedCostMatrix

bHullPhenotype = (CellPhenotypes.hullPhenoSet(1,:) == hullID);
if ( nnz(bHullPhenotype) > 0 )
    CellPhenotypes.hullPhenoSet = CellPhenotypes.hullPhenoSet(:,~bHullPhenotype);
end

clearedHull = Helper.MakeEmptyStruct(CellHulls);
clearedHull.deleted = true;

CellHulls(hullID) = clearedHull;

% Clear GraphEdits and cache-cost edges for deleted cell
GraphEdits(hullID,:) = 0;
GraphEdits(:,hullID) = 0;

ResegLinks(hullID,:) = 0;
ResegLinks(:,hullID) = 0;

CachedCostMatrix(hullID,:) = 0;
CachedCostMatrix(:,hullID) = 0;
end

