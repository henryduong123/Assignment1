% GraphEditRemoveEdge(trackID, time)
% Add (-1) edges to GraphEdits structure for a user removal of a tracked
% edge, places a -1 on all edges for the given tree, this avoids mitosis
% "jumping" from one track to another on the same tree

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

function GraphEditRemoveEdge(trackID, time)
    global CellTracks CellFamilies GraphEdits CachedCostMatrix
    
    nextHull = Helper.GetNearestTrackHull(trackID, time, 1);
    if ( nextHull == 0 )
        return;
    end
    
    possibleFamilyParents = [];
    familyID = CellTracks(trackID).familyID;
    for i=1:length(CellFamilies(familyID).tracks)
        checkTrack = CellFamilies(familyID).tracks(i);
        possibleFamilyParents = [possibleFamilyParents Helper.GetNearestTrackHull(checkTrack, time-1, -1)];
    end
    
    nzParentHulls = possibleFamilyParents(possibleFamilyParents > 0);
    for i=1:length(nzParentHulls)
        GraphEdits(nzParentHulls(i),nextHull) = -1;
        
        % Update cached cost matrix
        CachedCostMatrix(nzParentHulls(i),nextHull) = 0;
    end
    
    Tracker.UpdateCachedCosts(nzParentHulls, nextHull);
end

