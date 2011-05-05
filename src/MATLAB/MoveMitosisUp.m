%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
%     This file is part of LEVer.exe
%     (C) 2011 Andrew Cohen, Eric Wait and Mark Winter
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function MoveMitosisUp(time,siblingTrackID)
% MoveMitosisUp(time,siblingTrackID) will move the Mitosis event up the
% tree.  This function takes the hulls from the parent between the old
% mitosis time and the given time and attaches them to the given track.


global CellTracks

%remove hulls from parent
hash = time - CellTracks(CellTracks(siblingTrackID).parentTrack).startTime + 1;
hulls = CellTracks(CellTracks(siblingTrackID).parentTrack).hulls(hash:end);
CellTracks(CellTracks(siblingTrackID).parentTrack).hulls(hash:end) = 0;
RehashCellTracks(CellTracks(siblingTrackID).parentTrack,CellTracks(CellTracks(siblingTrackID).parentTrack).startTime);

%add hulls to sibling
for i=1:length(hulls)
    AddHullToTrack(hulls(i),siblingTrackID,[]);
end
end