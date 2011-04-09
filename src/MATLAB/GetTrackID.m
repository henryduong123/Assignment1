function trackID = GetTrackID(hullID)
%Given a hull ID a track ID will be returned or [] if none found

%--Eric Wait

global CellHulls HashedCells

trackID = [];

if(hullID>length(CellHulls))
    return
else
    hullTime = CellHulls(hullID).time;
    hashedCellIndex = [HashedCells{hullTime}.hullID] == hullID;
    if(isempty(hashedCellIndex)),return,end
    trackID = HashedCells{hullTime}(hashedCellIndex).trackID;
end
end
