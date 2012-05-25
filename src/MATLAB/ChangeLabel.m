% droppedTracks = ChangeLabel(time,currentTrack,desiredTrack)
% if time==[] then the whole track will be renamed to the desiredTrack
% ChangeLabel will change the currentTrack to the desiredTrack's label.
% The list of tracks that have been removed from the tree due to this label
% change will be returned.

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

function droppedTracks = ChangeLabel(time,currentTrack,desiredTrack)
global CellTracks

droppedTracks = [];
currentParent = [];

if(isempty(time))
    time = CellTracks(currentTrack).startTime;
end

if (time>CellTracks(desiredTrack).startTime)
    %% The desiredTrack is before the currentTrack
    % Remove any future track on the desiredTrack
    if (time<CellTracks(desiredTrack).endTime)
        droppedTracks = [droppedTracks RemoveFromTree(desiredTrack,time)];
    end
    %Gather the hulls to move and leave the rest on the currentTrack
    startHash = time-CellTracks(currentTrack).startTime+1;
    endHash = length(CellTracks(currentTrack).hulls);
    hulls = CellTracks(currentTrack).hulls(startHash:endHash);
else
    %% The currentTrack is before the desiredTrack
    % Remove any future track on the currentTrack
    currentParent = CellTracks(currentTrack).parentTrack;
    droppedTracks = [droppedTracks RemoveFromTree(currentTrack,time)];
    hulls = CellTracks(currentTrack).hulls;
end

%% Move the hulls from the currentTrack to the desiredTrack
for i=1:length(hulls)
    droppedTracks = [droppedTracks RemoveHullFromTrack(hulls(i))];
    droppedTracks = [droppedTracks AddHullToTrack(hulls(i),desiredTrack)];
end

%% Clean up
% Clear out any empty tracks from the list
droppedTracks = droppedTracks(arrayfun(@(x)(~isempty(x.hulls)),CellTracks(droppedTracks)));

% Reconnect any orphaned children that match up exactly
droppedTracks = setdiff(droppedTracks,ReconnectParentWithChildren(desiredTrack,droppedTracks));
droppedTracks = setdiff(droppedTracks,ReconnectParentWithChildren(currentParent,droppedTracks));

end

% reconnectedTracks = ReconnectParentWithChildren(parentTrack,childrenTracks)
% This will not make this connection if the parent already has children or
% there are no children that start on parent.endTime +1
% Returns the list of children attached to the parent
function reconnectedTracks = ReconnectParentWithChildren(parentTrack,childrenTracks)
global CellTracks

reconnectedTracks = [];

if(isempty(parentTrack)), return, end

for i=1:length(childrenTracks)
    if (CellTracks(parentTrack).endTime==CellTracks(childrenTracks(i)).startTime-1)
        reconnectedTracks = [reconnectedTracks childrenTracks(i)];
    end
end

if (isempty(reconnectedTracks)), return, end

if(length(reconnectedTracks)~=2)
    error('More then two children trying to get reconnected!');
end

CellTracks(reconnectedTracks(1)).siblingTrack = reconnectedTracks(2);
CellTracks(reconnectedTracks(2)).siblingTrack = reconnectedTracks(1);
    
for i=1:length(reconnectedTracks)
    CellTracks(reconnectedTracks(i)).parentTrack = parentTrack;
    CellTracks(parentTrack).childrenTracks = [CellTracks(parentTrack).childrenTracks reconnectedTracks(i)];
    ChangeTrackAndChildrensFamily(CellTracks(reconnectedTracks(i)).familyID,...
        CellTracks(parentTrack).familyID,reconnectedTracks(i));
end
end