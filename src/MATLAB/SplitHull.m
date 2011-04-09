function newTrackIDs = SplitHull(hullID, k)
% Attempt to split hull corresponding to hullId into k pieces, and update
% associated data structures if successful.

%--Mark Winter

global CellHulls CellFamilies

newHulls = ResegmentHull(CellHulls(hullID), k);

if ( isempty(newHulls) )
    return;
end

% Just arbitrarily assign clone's hull for now
CellHulls(hullID) = newHulls(1);

% Other hulls are just added off the clone
newFamilyIDs = [];
for i=2:length(newHulls)
    CellHulls(end+1) = newHulls(i);
    newFamilyIDs = [newFamilyIDs NewCellFamily(length(CellHulls), newHulls(i).time)];
end
newTrackIDs = [CellFamilies(newFamilyIDs).rootTrackID];
end
