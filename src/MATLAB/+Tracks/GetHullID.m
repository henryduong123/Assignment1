% hullID = GetHullID(time, trackID)
% Helper function to get a hull given a trackID and time

function hullID = GetHullID(time, trackID)
global CellTracks
hullID = 0;

if (time<CellTracks(trackID).startTime), return, end
if (time>CellTracks(trackID).endTime), return, end

hullID = CellTracks(trackID).hulls(time - CellTracks(trackID).startTime + 1);
end