%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
%     This file is part of LEVer.exe
%     (C) 2011 Andrew Cohen, Eric Wait and Mark Winter
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function newTrackIDs = SplitHull(hullID, k)
% Attempt to split hull corresponding to hullId into k pieces, and update
% associated data structures if successful.


global CellHulls CellFamilies HashedCells GraphEdits

oldCOM = CellHulls(hullID).centerOfMass;
oldTracks = [HashedCells{CellHulls(hullID).time}.trackID];

newHulls = ResegmentHull(CellHulls(hullID), k, 1);

if ( isempty(newHulls) )
    newTrackIDs = [];
    return;
end

% Just arbitrarily assign clone's hull for now
CellHulls(hullID) = newHulls(1);
newHullIDs = hullID;

% Drop old graphedits on a manual split
GraphEdits(hullID,:) = 0;
GraphEdits(:,hullID) = 0;

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
