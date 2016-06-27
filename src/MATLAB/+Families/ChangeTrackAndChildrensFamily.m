%ChangeTrackAndChildrensFamily(newFamilyID,trackID)
%This will remove the tree rooted at the given trackID from the given
%oldFamily and put them in the newFamily
%This DOES NOT make the parent child relationship, it is just updates the
%CellFamilies data structure.

% Change Log
% ECW 6/6/12 rewrite
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
%     Copyright 2011-2016 Andrew Cohen
%
%     This file is part of LEVer - the tool for stem cell lineaging. See
%     http://n2t.net/ark:/87918/d9rp4t for details
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

function ChangeTrackAndChildrensFamily(newFamilyID,trackID)
%get the full list of tracks to be updateded
traverseTree(newFamilyID,trackID);

Families.UpdateFamilyTimes(newFamilyID);
end

function traverseTree(newFamilyID,trackID)
%recursive helper function to traverse tree and gather track IDs
%will add the tracks to the new family along the way
global CellFamilies CellTracks

curFamilyID = CellTracks(trackID).familyID;
if ( newFamilyID ~= curFamilyID )
    Families.RemoveTrackFromFamily(trackID);
    %add track
    CellFamilies(newFamilyID).tracks = [CellFamilies(newFamilyID).tracks trackID];
    CellTracks(trackID).familyID = newFamilyID;
end
   
for i=1:length(CellTracks(trackID).childrenTracks)
    traverseTree(newFamilyID, CellTracks(trackID).childrenTracks(i));
end
end
