function newTrackIDs = SplitHull(hullID, k)
% Attempt to split hull corresponding to hullId into k pieces, and update
% associated data structures if successful.

%--Mark Winter

global CellHulls CellFamilies HashedCells

oldCOM = CellHulls(hullID).centerOfMass;
oldTracks = [HashedCells{CellHulls(hullID).time}.trackID];

newHulls = ResegmentHull(CellHulls(hullID), k);

if ( isempty(newHulls) )
    newTrackIDs = [];
    return;
end

% Just arbitrarily assign clone's hull for now
CellHulls(hullID) = newHulls(1);
newHullIDs = hullID;

% Other hulls are just added off the clone
newFamilyIDs = [];
for i=2:length(newHulls)
    CellHulls(end+1) = newHulls(i);
    newFamilyIDs = [newFamilyIDs NewCellFamily(length(CellHulls), newHulls(i).time)];
    newHullIDs = [newHullIDs length(CellHulls)];
end
% newTrackIDs = [CellFamilies(newFamilyIDs).rootTrackID];

newTrackIDs = TrackSplitHulls(newHullIDs, oldTracks, oldCOM);
end
