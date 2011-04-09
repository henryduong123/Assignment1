function RemoveHull(hullID)
% RemoveHull(hullID) will LOGICALLY remove the hull.  Which means that the
% hull will have a flag set that means that it does not exist anywhere and
% should not be drawn on the cells figure

%--Eric Wait

global CellTracks HashedCells CellHulls

trackID = GetTrackID(hullID);

%remove hull from its track
index = find(CellTracks(trackID).hulls==hullID);
CellTracks(trackID).hulls(index) = 0;
if(1==index)
    index = find(CellTracks(trackID).hulls,1,'first');
    RehashCellTracks(trackID,CellHulls(CellTracks(trackID).hulls(index)).time);
elseif(index==length(CellTracks(trackID).hulls))
    RehashCellTracks(trackID,CellTracks(trackID).startTime);
end

%remove hull from HashedCells
time = CellHulls(hullID).time;
index = [HashedCells{time}.hullID]==hullID;
HashedCells{time}(index) = [];

CellHulls(hullID).deleted = 1;
end
