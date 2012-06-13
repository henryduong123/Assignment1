% ClearHull( hullID )
% Clears the hull and marks it deleted

% ChangeLog:
% EW 6/8/12 created
function ClearHull( hullID )
global CellHulls

CellHulls(hullID).time = [];
CellHulls(hullID).points = [];
CellHulls(hullID).centerOfMass = [];
CellHulls(hullID).indexPixels = [];
CellHulls(hullID).imagePixels = [];
CellHulls(hullID).deleted = 1;
CellHulls(hullID).userEdited = [];
end

