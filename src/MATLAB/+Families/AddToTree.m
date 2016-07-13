% AddToTree(addTrack, ontoTrack)
% Low level function that adds one onto another as a mitosis event
% Throws an error if:
%   addTrack.startTime < ontoTrack.startTime
%   addTrack.startTime > ontoTrack.endTime

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


% ChangLog
% EW 6/7/12 Created
function droppedTracks = AddToTree(addTrack, ontoTrack)
global CellTracks

%% Error Checking
if (CellTracks(addTrack).startTime<=CellTracks(ontoTrack).startTime || ...
        CellTracks(addTrack).startTime>CellTracks(ontoTrack).endTime)
    error('Tried to add track %d (startTime: %d) onto track %d (startTime: %d, endTime: %d)',...
        addTrack,CellTracks(addTrack).startTime,ontoTrack,CellTracks(ontoTrack).startTime,...
        CellTracks(ontoTrack).endTime);
end

droppedTracks = Families.RemoveFromTreePrune(addTrack);

%% Split the track that will be the parent
newSibling = Families.RemoveFromTreePrune(ontoTrack,CellTracks(addTrack).startTime);

if (length(newSibling)~=1)
    list = sprintf(' %d, ',newSibling);
    error('Dropped too many tracks %s',list);
end

%% Add both the droppedTrack and the addTrack as children
Families.ReconnectParentWithChildren(ontoTrack,[addTrack newSibling]);
end