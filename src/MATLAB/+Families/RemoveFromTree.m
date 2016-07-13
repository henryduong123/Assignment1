% droppedTracks = RemoveFromTree(removeTrackID,time)
% time is optional
% Is similar to RemoveFromTreePrune but keeps the other child.  This will
% straighten out the parent track with the sibling of the given track

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
function droppedTracks = RemoveFromTree(removeTrackID,time)
global CellTracks

if (~exist('time','var'))
    time = CellTracks(removeTrackID).startTime;
end

parentID = CellTracks(removeTrackID).parentTrack;
siblingID = CellTracks(removeTrackID).siblingTrack;

%% Drop off the tree
droppedTracks = Families.RemoveFromTreePrune(removeTrackID,time);
if (Helper.WasDropped(siblingID,droppedTracks) && ~isempty(parentID))
    %reconect sibling
    droppedTracks = [droppedTracks Tracks.ChangeLabel(siblingID,parentID)];
    droppedTracks = setdiff(droppedTracks,siblingID);
end
end

