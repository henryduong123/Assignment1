% ClearHull( hullID )
% Clears the hull and marks it deleted

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

