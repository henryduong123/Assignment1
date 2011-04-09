function newTrackIDs = SplitHull(hullID, k)
% Attempt to split hull corresponding to hullId into k pieces, and update
% associated data structures if successful.

%--Mark Winter

global CellHulls

newHulls = ResegmentHull(CellHulls(hullID), k);

if ( isempty(newHulls) )
    return;
end

% Just arbitrarily assign clone's hull for now
CellHulls(hullID) = newHulls(1);

newTrackIDs = [length(CellHulls)+1 length(CellHulls)+length(newHulls)];
% Other hulls are just added off the clone
for i=2:length(newHulls)
    CellHulls(end+i-1) = newHulls(i);
    NewCellFamily(length(CellHulls), newHulls(i).time);
end

end
