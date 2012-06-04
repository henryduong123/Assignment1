% removedTracks = RemoveHullFromTrack(hullID)% 
% *** Must be called before adding this hull to another track***
%
% Removes a hull from a track deleting the track if necessary.
% Will return the track numbers that have been removed from the tree or
% empty.  These track numbers will be consistant to that prior to call.
%
% ***HashedCells will have an empty track for this hull and this hull will
% not be attached to any track***

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

function removedTracks = RemoveHullFromTrack(hullID)
    global CellTracks CellHulls HashedCells
    
    removedTracks = [];
    trackID = Tracks.GetTrackID(hullID);
    
    if (isempty(trackID))
        error('Removing a hull from a track that does not exist!\nHullID:%d',hullID);
    end
    
    %% Hull is at the head of the track
    if (length(CellTracks(trackID).hulls) == 1 || CellTracks(trackID).startTime == CellHulls(hullID).time)
        if (~isempty(CellTracks(trackID).parentTrack))
            %TODO fix func call
            removedTracks = [removedTracks Families.RemoveFromTree(trackID)];
        end
    end
    
    %% Hull is at the tail of the track
    if (length(CellTracks(trackID).hulls) == 1 || CellTracks(trackID).endTime == CellHulls(hullID).time)
        if (~isempty(CellTracks(trackID).childrenTracks))
            %TODO fix func call
            removedTracks = [removedTracks Families.RemoveFromTree(CellTracks(trackID).childrenTracks(1))];
        end
    end
    
    %% Update    
    %update hashed cells
    index = [HashedCells{CellHulls(hullID).time}.hullID]==hullID;
    HashedCells{CellHulls(hullID).time}(index).trackID = [];
    
    %Remove the hull from the track
    CellTracks(trackID).hulls(CellTracks(trackID).hulls==hullID) = 0;
    Tracks.RehashCellTracks(trackID);
    
    %% Check if track is empty
    if (isempty(CellTracks(trackID).hulls))
        Tracks.ClearTrack(trackID);
    end
end