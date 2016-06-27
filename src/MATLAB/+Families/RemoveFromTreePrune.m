% droppedTracks = RemoveFromTreePrune(trackID,time)
% time is optional
% This will remove the track and any of its children from its current family
% and create a new family rooted at the given track
% Any siblings of the given track will also be dropped.
% droppedTracks will be the list of tracks that were dropped from the
% family (they will be the roots of their subtrees)

% ChangeLog
% EW 6/6/12 rewriten
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

function droppedTracks = RemoveFromTreePrune(trackID,time)
global CellFamilies CellTracks

if (~exist('time','var'))
    time = CellTracks(trackID).startTime;
end

droppedTracks = [];

if (time<CellTracks(trackID).startTime || time>CellTracks(trackID).endTime)
    return;
end

hash = time - CellTracks(trackID).startTime + 1;

%Make sure we're splitting the track on a non-zero hull
nzidx = find(CellTracks(trackID).hulls(hash:end) > 0, 1);
if ( isempty(nzidx) )
    error('Tried to RemoveFromTree with a track where there were no hulls after given time.\n Time=%d, trackID=%d\n',time,trackID);
end

nzidx = nzidx + hash -1;

oldFamilyID = CellTracks(trackID).familyID;

if (time == CellTracks(trackID).startTime)
    %% whole track is being removed
    if (~isempty(CellTracks(trackID).parentTrack))
        % remove children from parent
        CellTracks(CellTracks(trackID).parentTrack).childrenTracks = [];
        CellTracks(trackID).parentTrack = [];
        % remove sibling connection
        CellTracks(CellTracks(trackID).siblingTrack).parentTrack = [];
        CellTracks(CellTracks(trackID).siblingTrack).siblingTrack = [];
        droppedTracks = CellTracks(trackID).siblingTrack;
        CellTracks(trackID).siblingTrack = [];
    end
    droppedTracks = [droppedTracks trackID];
else    
    %% Create a new family with the first hull
    newFamilyID = Families.NewCellFamily(CellTracks(trackID).hulls(nzidx));
    CellTracks(trackID).hulls(nzidx) = 0;
    newTrackID = CellFamilies(newFamilyID).rootTrackID;
    droppedTracks = newTrackID;
    
    %move the hulls from the old track to the new
    for i=nzidx+1:length(CellTracks(trackID).hulls)
        droppedTracks = [droppedTracks Tracks.AddHullToTrack(CellTracks(trackID).hulls(i),newTrackID,[])];
        CellTracks(trackID).hulls(i) = 0;
    end
    
    %move the children of the old track to the new
    if (~isempty(CellTracks(trackID).childrenTracks))
        CellTracks(newTrackID).childrenTracks = CellTracks(trackID).childrenTracks;
        
        for i=1:length(CellTracks(newTrackID).childrenTracks)
            CellTracks(CellTracks(newTrackID).childrenTracks(i)).parentTrack = newTrackID;
        end
        
        CellTracks(trackID).childrenTracks = [];
    end
    
    Tracks.RehashCellTracks(trackID);
end

for i=1:length(droppedTracks)
    newFam = Families.CreateEmptyFamily();
    Families.ChangeTrackAndChildrensFamily(newFam,droppedTracks(i));
end
end
