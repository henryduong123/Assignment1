% MoveMitosisUp(time,siblingTrackID) will move the Mitosis event up the
% tree.  This function takes the hulls from the parent between the old
% mitosis time and the given time and attaches them to the given track.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
%     Copyright 2011 Andrew Cohen, Eric Wait and Mark Winter
%
%     This file is part of LEVer - the tool for stem cell lineaging. See
%     https://pantherfile.uwm.edu/cohena/www/LEVer.html for details
% 
%     LEVer is free software: you can redistribute it and/or modify
%     it under the terms of the GNU General Public License as published by
%     the Free Software Foundation, either version 3 of the License, or
%     (at your option) any later version.
% 
%     LEVer is distributed in the hope that it will be useful,
%     but WITHOUT ANY WARRANTY; without even the implied warranty of
%     MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
%     GNU General Public License for more details.
% 
%     You should have received a copy of the GNU General Public License
%     along with LEVer in file "gnu gpl v3.txt".  If not, see 
%     <http://www.gnu.org/licenses/>.
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function MoveMitosisUp(time,siblingTrackID)

global CellTracks

%remove hulls from parent
hash = time - CellTracks(CellTracks(siblingTrackID).parentTrack).startTime + 1;
hulls = CellTracks(CellTracks(siblingTrackID).parentTrack).hulls(hash:end);
CellTracks(CellTracks(siblingTrackID).parentTrack).hulls(hash:end) = 0;
Tracks.RehashCellTracks(CellTracks(siblingTrackID).parentTrack,CellTracks(CellTracks(siblingTrackID).parentTrack).startTime);

%add hulls to sibling
for i=1:length(hulls)
    Tracks.AddHullToTrack(hulls(i),siblingTrackID,[]);
end
end