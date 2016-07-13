% droppedTracks = SwapLabels(track1,track2,time) 
% This function will swap the hulls of the two tracks from the given time
% forward.  Any children will also be swaped
% Throws error:
%   if any params are empty
%   time is not within start/end of each track

% ChangeLog:
% EW 6/7/12 rewrite
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
%     Copyright 2016 Drexel University
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

function droppedTracks = SwapLabels(track1,track2,time)
global CellTracks

%% Error Check
if (isempty(track1) || isempty(track2) || isempty(time))
    error('SwapLabels needs track1 %d, track2 %d, and time %d',track1,track2,time);
end
if (Tracks.GetHullID(time,track1)==0)
    error('Track %d has no hull to swap with at time %d,',track1,time);
end
if (Tracks.GetHullID(time,track2)==0)
    error('Track %d has no hull to swap with at time %d,',track2,time);
end
if (CellTracks(track1).startTime>time ||...
        CellTracks(track2).startTime>time ||...
        CellTracks(track1).endTime<time ||...
        CellTracks(track2).endTime<time)
    error('Cannot swap tracks %d & %d because the times conflict.\nTime: %d\nTrack: %d, start %d, end %d\Track: %d, start %d, end%d',...
        track1,track2,time,track1,CellTracks(track1).startTime,CellTracks(track1).endTime,track2,CellTracks(track2).startTime,CellTracks(track2).endTime);
end

%% Get Sturcture to fix back up
% Get the siblings and parents from the tracks to see who fell off the tree
track1Sibling = CellTracks(track1).siblingTrack;
track1Parent = CellTracks(track1).parentTrack;
track2Sibling = CellTracks(track2).siblingTrack;
track2Parent = CellTracks(track2).parentTrack;

%% Drop the tracks at the given time
droppedTracks = Tracks.ChangeLabel(track1,track2,time);
newTrack2 = setdiff(droppedTracks,[track1 track2 track1Sibling track2Sibling]);
droppedTracks = [droppedTracks Tracks.ChangeLabel(newTrack2,track1,time)];
droppedTracks = setdiff(droppedTracks,newTrack2);

if (Helper.WasDropped(track1Sibling,droppedTracks))
    Families.ReconnectParentWithChildren(track1Parent,[track1 track1Sibling]);
    droppedTracks = setdiff(droppedTracks,[track1 track1Sibling]);
end

if (Helper.WasDropped(track2Sibling,droppedTracks))
    Families.ReconnectParentWithChildren(track2Parent,[track2 track2Sibling]);
    droppedTracks = setdiff(droppedTracks,[track2 track2Sibling]);
end
end

