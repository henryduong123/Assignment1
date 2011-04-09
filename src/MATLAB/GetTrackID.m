function trackID = GetTrackID(hullID)
%Given a hull ID a track ID will be returned

%--Eric Wait

global CellHulls HashedCells

hullTime = CellHulls(hullID).time;
hashedCellIndex = [HashedCells{hullTime}.hullID] == hullID;
trackID = HashedCells{hullTime}(hashedCellIndex).trackID;
end
