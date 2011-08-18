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

function AddSingleHullToTrack(oldTrackID,newTrackID)
% AddSingleHullToTrack(oldTrackID,newTrackID)
% This function is indended for the oldTrack to be just a single hull,
% typicaly when a hull has been split and now that new hull is being added
% to a track.  This function takes the hull and merges it into the
% newTrack.  The parent and child relationships of the newTrack will be
% maintained.


global CellTracks HashedCells CellFamilies Figures

if(~isempty(CellTracks(oldTrackID).parentTrack) && ...
        ~isempty(CellTracks(oldTrackID).childrenTracks) && ...
        1~=length(CellTracks(oldTrackID).hulls))
    error([num2str(oldTrackID) ' is not a single hull track or has a parent/child']);
end

if(~any([CellTracks(CellTracks(newTrackID).childrenTracks).endTime]<CellTracks(oldTrackID).startTime))
    RemoveChildren(newTrackID);
    AddHullToTrack(CellTracks(oldTrackID).hulls(1),newTrackID,[]);
elseif(CellTracks(oldTrackID).startTime<CellTracks(newTrackID).startTime)
    %old before new
    if(~isempty(CellTracks(newTrackID).parentTrack))
        MoveMitosisUp(CellTracks(oldTrackID).startTime,...
            CellTracks(newTrackID).siblingTrack);
    end
    AddHullToTrack(CellTracks(oldTrackID).hulls(1),newTrackID,[]);
elseif(CellTracks(oldTrackID).startTime>CellTracks(newTrackID).endTime)
    %new before old
    if(~isempty(CellTracks(newTrackID).childrenTracks))
        MoveMitosisDown(CellTracks(oldTrackID).startTime,newTrackID);
    end
    AddHullToTrack(CellTracks(oldTrackID).hulls(1),newTrackID,[]);
else
    %old within new
    if(~isempty(find([HashedCells{Figures.time}.trackID]==newTrackID,1)))
        SwapTrackLabels(CellTracks(oldTrackID).startTime,oldTrackID,newTrackID);
    else
        AddHullToTrack(CellTracks(oldTrackID).hulls(1),newTrackID,[]);
    end
end

%clean out old track/family
familyID = CellTracks(oldTrackID).familyID;
CellFamilies(familyID).rootTrackID = [];
CellFamilies(familyID).tracks = [];
CellFamilies(familyID).startTime = [];
CellFamilies(familyID).endTime = [];

ClearTrack(oldTrackID);
end
