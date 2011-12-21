% SplitHull.m - Attempt to split hull corresponding to hullId into k pieces
% and update associated data structures if successful.

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

function newTrackIDs = SplitHull(hullID, k)

global CellHulls CellFeatures CellFamilies HashedCells GraphEdits

oldCOM = CellHulls(hullID).centerOfMass;
oldTracks = [HashedCells{CellHulls(hullID).time}.trackID];

if ( isempty(CellFeatures) )
    splitFeat = [];
else
    splitFeat = CellFeatures(hullID);
end

% [newHulls newFeatures] = ResegmentHull(CellHulls(hullID), splitFeat, k, 1);
[newHulls newFeatures] = WatershedSplitCell(CellHulls(hullID), splitFeat, k);

if ( isempty(newHulls) )
    newTrackIDs = [];
    return;
end

for i=1:length(newHulls)
    newHulls(i).userEdited = 1;
end

% Just arbitrarily assign clone's hull for now
CellHulls(hullID) = newHulls(1);

% Set features if valid
if ( ~isempty(CellFeatures) )
    CellFeatures(hullID) = newFeatures(1);
end

newHullIDs = hullID;

% Drop old graphedits on a manual split
GraphEdits(hullID,:) = 0;
GraphEdits(:,hullID) = 0;

% Other hulls are just added off the clone
newFamilyIDs = [];
for i=2:length(newHulls)
    CellHulls(end+1) = newHulls(i);
    
    % Set features if valid
    if ( ~isempty(CellFeatures) )
        CellFeatures(end+1) = newFeatures(i);
    end
    
    newFamilyIDs = [newFamilyIDs NewCellFamily(length(CellHulls), newHulls(i).time)];
    newHullIDs = [newHullIDs length(CellHulls)];
end

newTrackIDs = TrackSplitHulls(newHullIDs, oldTracks, oldCOM);
end
