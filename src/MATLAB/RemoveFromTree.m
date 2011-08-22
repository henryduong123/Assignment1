% newFamily = RemoveFromTree(time,trackID,dealWithSibling)
% This will remove the track and any of its children from its current family
% and create a new family rooted at the given track
% If you want the current track's sibling to be combined with its parent,
% pass combineSiblingWithParent='yes' otherwise 'no'
%
% ***IF YOU PASS 'NO', YOU MUST DEAL WITH ANY SIBLING YOURSELF!!! OTHERWISE
% THERE WILL BE ISSUES WITH THE DATA****

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

function newFamilyID = RemoveFromTree(time,trackID,combineSiblingWithParent)

global CellFamilies CellTracks CellHulls

hash = time - CellTracks(trackID).startTime + 1;

newFamilyID = [];
% Make sure we're splitting the track on a non-zero hull
nzidx = find(CellTracks(trackID).hulls(hash:end) > 0, 1);
if ( isempty(nzidx) )
    % Track has no hulls from hash onward
    return;
end
hash = hash + nzidx - 1;
time = time + nzidx - 1;

oldFamilyID = CellTracks(trackID).familyID;
newFamilyID = NewCellFamily(CellTracks(trackID).hulls(hash),time);
newTrackID = CellFamilies(newFamilyID).rootTrackID;
CellTracks(trackID).hulls(hash) = 0;

for i=1:length(CellTracks(trackID).hulls(hash:end))-1
    if(CellTracks(trackID).hulls(hash+i)~=0)
        AddHullToTrack(CellTracks(trackID).hulls(hash+i),newTrackID,[]);
    end
    CellTracks(trackID).hulls(hash+i) = 0;
end

for i=1:length(CellTracks(trackID).childrenTracks)
    ChangeTrackAndChildrensFamily(oldFamilyID,newFamilyID,CellTracks(trackID).childrenTracks(i));
    CellTracks(CellTracks(trackID).childrenTracks(i)).parentTrack = newTrackID;
end

if(~isempty(find(CellFamilies(oldFamilyID).tracks==newTrackID, 1)))
    CellFamilies(newFamilyID).tracks(end+1) = newTrackID;
end
CellTracks(newTrackID).familyID = newFamilyID;
CellTracks(newTrackID).childrenTracks = CellTracks(trackID).childrenTracks;
for i=1:length(CellTracks(newTrackID).childrenTracks)
    CellTracks(CellTracks(newTrackID).childrenTracks(i)).parentTrack = newTrackID;
end
CellTracks(trackID).childrenTracks = [];

%clean up old track
if(isempty(find([CellTracks(trackID).hulls]~=0, 1)))
    if(~isempty(CellTracks(trackID).siblingTrack)&& strcmp(combineSiblingWithParent,'yes'))
        CombineTrackWithParent(CellTracks(trackID).siblingTrack);
    end
    RemoveTrackFromFamily(trackID);
    if(~isempty(CellTracks(trackID).parentTrack))
        index = CellTracks(CellTracks(trackID).parentTrack).childrenTracks==trackID;
        CellTracks(CellTracks(trackID).parentTrack).childrenTracks(index) = [];
    end
    ClearTrack(trackID);
else
    index = find([CellTracks(trackID).hulls]~=0, 1,'last');
    CellTracks(trackID).endTime = CellHulls(CellTracks(trackID).hulls(index)).time;
end

if ( ~isempty(CellFamilies(oldFamilyID).tracks) )
    CellFamilies(oldFamilyID).startTime = min([CellTracks(CellFamilies(oldFamilyID).tracks).startTime]);
    CellFamilies(oldFamilyID).endTime = max([CellTracks(CellFamilies(oldFamilyID).tracks).endTime]);
end

end
