% function droppedTracks = AddHullToTrack(hullID,trackID,previousHullID)
% Remove hulls from their current track prior to adding them to a new track
%  The hullID will be added to the track and if the added hull conficts
%  with a mitosis event, the tracks dropped from the tree will be returned.
%
%  If trackID is given, previousHullID is not used.  Safe to
%  send [] for either trackID or previousHullID.
%  Prereq to leave trackID empty - Track to be added to exists and the
%  previousHullID exists in that track.  Also, it has been
%  removed from any previous track assosiation.

% UpdateLog:
% EW 6/8/12 rewrite
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

function droppedTracks = AddHullToTrack(hullID,trackID,previousHullID)
global HashedCells CellTracks CellHulls CellFamilies

droppedTracks = [];

if ( ~isscalar(hullID) || (hullID <= 0) || (hullID > length(CellHulls)) )
    error('AddHullToTrack - hullID argument must be a valid scalar cell ID\n hullID:%d, trackID:%d, previousHullID:%d',...
        hullID,trackID,previousHullID);
end

%% This is when the track is not known and is used in converting legacy data struct
if(isempty(trackID))
    %find the track to add this hull to
    previousTime = CellHulls(previousHullID).time;
    index = find([HashedCells{previousTime}(:).hullID]==previousHullID);
    if(isempty(index))
        error('Previous CellHull -- %d not found!\n hullID:%d, trackID:%d, previousHullID:%d',...
        previousHullID,hullID,trackID,previousHullID);
    end
    %add the hullID to track
    trackID = HashedCells{previousTime}(index).trackID;
end

%% Does this add conflict with a mitosis event?
time = CellHulls(hullID).time;

if (~isempty(CellTracks(trackID).hulls))
    % Is this hull being added to the head of the track and does it have a
    % parent?
    if(time<CellTracks(trackID).startTime && ~isempty(CellTracks(trackID).parentTrack))
        %Remove this track from the family
        droppedTracks = [droppedTracks Families.RemoveFromTree(trackID)];
    end
    
    %Is this hull being added to the tail of the track and does it have
    %children?
    if(time>CellTracks(trackID).endTime && ~isempty(CellTracks(trackID).childrenTracks))
        %Drop the children
        for i=1:length(CellTracks(trackID).childrenTracks)
            droppedTracks = [droppedTracks Families.RemoveFromTree(CellTracks(trackID).childrenTracks(i))];
        end
    end
else
    curFamilyID = length(CellFamilies) + 1;
    
    %setup defaults for family tree
    CellFamilies(curFamilyID).rootTrackID = trackID;
    CellFamilies(curFamilyID).tracks = trackID;
    CellFamilies(curFamilyID).startTime = time;
    CellFamilies(curFamilyID).endTime = time;
    CellTracks(trackID).familyID = curFamilyID;
    CellTracks(trackID).color = UI.GetNextColor();
end

%% Add hull
CellTracks(trackID).hulls = [CellTracks(trackID).hulls hullID];

%% Update
Tracks.RehashCellTracks(trackID);
Hulls.AddHashedCell(hullID,trackID);
end
