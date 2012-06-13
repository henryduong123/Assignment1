% ContextRemoveFromTree.m - context menu callback function remove track or
% partial track from its current tree

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

function ContextRemoveFromTree(trackID,time)
global CellTracks 

if (~exist('time','var'))
    time = CellTracks(trackID).startTime;
end

if (isempty(CellTracks(trackID).parentTrack))
    return;
end

oldParent = CellTracks(trackID).parentTrack;

try
    Tracker.GraphEditRemoveEdge(trackID, time);
    droppedTracks = Families.RemoveFromTree(trackID, time);
    Editor.History('Push');
catch errorMessage
    Error.ErrorHandling(['RemoveFromTreePrune(' num2str(trackID) ' ' num2str(time) ') -- ' errorMessage.message],errorMessage.stack);
    return
end

Error.LogAction(['Removed part or all of ' num2str(trackID) ' from tree'],oldParent,trackID);

Families.ProcessNewborns();

UI.DrawTree(CellTracks(oldParent).familyID);
UI.DrawCells();
end
