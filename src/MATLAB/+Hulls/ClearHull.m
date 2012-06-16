% ClearHull( hullID )
% Clears the hull and marks it deleted

% ChangeLog:
% EW 6/8/12 created
function ClearHull( hullID )
global CellHulls GraphEdits CachedCostMatrix

CellHulls(hullID).time = [];
CellHulls(hullID).points = [];
CellHulls(hullID).centerOfMass = [];
CellHulls(hullID).indexPixels = [];
CellHulls(hullID).imagePixels = [];
CellHulls(hullID).deleted = 1;
CellHulls(hullID).userEdited = [];

% Clear GraphEdits and cache-cost edges for deleted cell
GraphEdits(hullID,:) = 0;
GraphEdits(:,hullID) = 0;

CachedCostMatrix(hullID,:) = 0;
CachedCostMatrix(:,hullID) = 0;
end

