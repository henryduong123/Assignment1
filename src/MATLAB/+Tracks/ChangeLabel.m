% droppedTracks = ChangeLabel(currentTrack, desiredTrack, time)
% This will move the currentTrack's hulls and children to the desiredTrack
% and return any tracks other tracks that have been dropped from the tree
% time is an optional parameter.  If time is not specified, the whole
% currentTrack is changed to the desiredTrack

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


% ChangeLog:
% EW 6/7/12 created
function [droppedTracks bErr] = ChangeLabel(currentTrack, desiredTrack, time)
global CellTracks

bErr = 1;
droppedTracks = [];

if (~exist('time','var'))
    time = CellTracks(currentTrack).startTime;
end

children = CellTracks(currentTrack).childrenTracks;

%Pass the work off to the lower function
droppedTracks = Tracks.ChangeTrackID(currentTrack,desiredTrack,time);

%Reattach any children that were dropped from the current track
if(length(intersect(droppedTracks,children))==2)
    Families.ReconnectParentWithChildren(desiredTrack,children);
    droppedTracks = setdiff(droppedTracks,children);
end

bErr = 0;
end