function RemoveHull(hullID)
% RemoveHull(hullID) will LOGICALLY remove the hull.  Which means that the
% hull will have a flag set that means that it does not exist anywhere and
% should not be drawn on the cells figure

%--Eric Wait

global HashedCells CellHulls CellTracks

trackID = GetTrackID(hullID);

if(isempty(trackID)),return,end

bNeedsUpdate = RemoveHullFromTrack(hullID, trackID);

%remove hull from HashedCells
time = CellHulls(hullID).time;
index = [HashedCells{time}.hullID]==hullID;
HashedCells{time}(index) = [];

CellHulls(hullID).deleted = 1;

RemoveSegmentationEdit(hullID);

if ( bNeedsUpdate )
    RemoveFromTree(CellTracks(trackID).startTime, trackID, 'yes');
    ProcessNewborns();
end
end
