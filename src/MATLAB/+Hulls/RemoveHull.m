% RemoveHull(hullID) will LOGICALLY remove the hull.  Which means that the
% hull will have a flag set that means that it does not exist anywhere and
% should not be drawn on the cells figure

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

function RemoveHull(hullID, bDontUpdateTree)

global HashedCells CellHulls CellTracks CellFamilies SegmentationEdits

if ( ~exist('bDontUpdateTree','var') )
    bDontUpdateTree = 0;
end

trackID = Tracks.GetTrackID(hullID);

if(isempty(trackID)),return,end

bNeedsUpdate = RemoveHullFromTrack(hullID, trackID);

%remove hull from HashedCells
time = CellHulls(hullID).time;
index = [HashedCells{time}.hullID]==hullID;
HashedCells{time}(index) = [];

CellHulls(hullID).deleted = 1;

Segmentation.RemoveSegmentationEdit(hullID, time);

if ( ~bDontUpdateTree && bNeedsUpdate )
    %TODO fix func call
    Families.RemoveFromTree(CellTracks(trackID).startTime, trackID, 'yes');
    Families.ProcessNewborns(1:length(CellFamilies),SegmentationEdits.maxEditedFrame);
end
end
