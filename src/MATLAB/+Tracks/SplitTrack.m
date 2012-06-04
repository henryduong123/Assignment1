% SplitTrack will break the given track off at the given hull and assign it
% a new trackID.  The new track will also be assigned as a child of the
% given track.  Returns the trackID of the new track, which is the first
% child of the given track.

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

function newTrackID = SplitTrack(trackID,hullID)

global CellFamilies CellTracks

%get all the hulls that come after hullID (in time that is)
%this also assumes that hulls are ordered
hullIndex = find([CellTracks(trackID).hulls]==hullID);

if(1==hullIndex)
    error('Trying to split a track at its root. TrackID: %d, HullID: %d',trackID,hullID);
    return
elseif(isempty(hullIndex))
    error('Trying to split a track at a non-existent hull. TrackID: %d, HullID: %d',trackID,hullID);
    return
end

hullList = CellTracks(trackID).hulls(hullIndex:end);
CellTracks(trackID).hulls(hullIndex:end) = [];
CellTracks(trackID).endTime = CellTracks(trackID).startTime + length(CellTracks(trackID).hulls) - 1;

newTrackID = length(CellTracks(1,:)) + 1;

%create the new track
CellTracks(newTrackID).familyID = CellTracks(trackID).familyID;
CellTracks(newTrackID).parentTrack = trackID;
CellTracks(newTrackID).siblingTrack = [];
CellTracks(newTrackID).hulls = hullList;
CellTracks(newTrackID).startTime = CellTracks(trackID).startTime + hullIndex - 1;
CellTracks(newTrackID).endTime = CellTracks(newTrackID).startTime + length(hullList) - 1;
CellTracks(newTrackID).color = CellTracks(trackID).color;

%attach the parents children to the newTrack
CellTracks(newTrackID).childrenTracks = CellTracks(trackID).childrenTracks;
for i=1:length(CellTracks(newTrackID).childrenTracks)
    CellTracks(CellTracks(newTrackID).childrenTracks(i)).parentTrack = newTrackID;
end
CellTracks(trackID).childrenTracks = newTrackID;

%update the family
trackIndex = length(CellFamilies(CellTracks(newTrackID).familyID).tracks) + 1;
CellFamilies(CellTracks(newTrackID).familyID).tracks(trackIndex) = newTrackID;

%update HashedCells
Tracks.UpdateHashedCellsTrackID(newTrackID,hullList,CellTracks(newTrackID).startTime);

end
