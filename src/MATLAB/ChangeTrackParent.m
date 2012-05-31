%ChangeTrackParent(parentTrackID,time,childTrackID) will take the
%childTrack and connect it to the parent track.  It also takes the hulls
%that exist in the parent track that are come after the childTrack root and
%makes a new track with said hulls.  When finished there should be a new
%track and the child track that are siblings with the parent track being
%the parent.

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

function ChangeTrackParent(parentTrackID,time,childTrackID)

global CellTracks CellFamilies

%see if the child exists before time
if(time > CellTracks(childTrackID).startTime)
    % TODO RemoveFromTree call
    newFamilyID = RemoveFromTree(time,childTrackID,'yes');
    childTrackID = CellFamilies(newFamilyID).rootTrackID;
end

%find where the child should attach to the parent
hash = time - CellTracks(parentTrackID).startTime + 1;
if(hash <= 0)
    error('Trying to attach a parent that comes after the child');
elseif(hash <= length(CellTracks(parentTrackID).hulls))
    parentHullID = CellTracks(parentTrackID).hulls(hash);
    siblingTrackID = SplitTrack(parentTrackID,parentHullID); % SplitTrack adds sibling to the parent already
else
    %just rename the child to the parent
    ChangeLabel(time,childTrackID,parentTrackID);
    return
end

oldFamilyID = CellTracks(childTrackID).familyID;
newFamilyID = CellTracks(siblingTrackID).familyID;

childIndex = length(CellTracks(parentTrackID).childrenTracks) + 1;
CellTracks(parentTrackID).childrenTracks(childIndex) = childTrackID;

%clean up old parent
if(~isempty(CellTracks(childTrackID).siblingTrack))
    CellTracks(CellTracks(childTrackID).siblingTrack).siblingTrack = [];
    CombineTrackWithParent(CellTracks(childTrackID).siblingTrack);
end
CellTracks(childTrackID).parentTrack = parentTrackID;

%Detatch childTrack and clean up child's family
if(oldFamilyID~=newFamilyID)
    ChangeTrackAndChildrensFamily(oldFamilyID,newFamilyID,childTrackID);
end

CellTracks(childTrackID).siblingTrack = siblingTrackID;
CellTracks(siblingTrackID).siblingTrack = childTrackID;

end
