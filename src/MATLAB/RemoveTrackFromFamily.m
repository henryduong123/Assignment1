% RemoveTrackFromFamily(trackID) only removes the track from the tracks
% list currently assosiated in the CellFamily entery and updated the other
% CellFamily fields.
% This is not intended to change the structure, just to keep the data
% correct

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

function RemoveTrackFromFamily(trackID)

global CellFamilies CellTracks
familyID = CellTracks(trackID).familyID;
if(isempty(familyID)),return,end

index = CellFamilies(familyID).tracks==trackID;

%remove track
CellFamilies(familyID).tracks(index) = [];

%update times
UpdateFamilyTimes(familyID);

%set new root
if(CellFamilies(familyID).rootTrackID == trackID)
    CellFamilies(familyID).rootTrackID = CellFamilies(familyID).tracks(index);
end
if(isempty(index))
    CellFamilies(familyID).tracks = [];
end
end
