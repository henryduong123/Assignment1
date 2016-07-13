% newTrackIDs = SplitHull(hullID, k)
% Attempt to split hull corresponding to hullId into k pieces
% and update associated data structures if successful.

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

function newTrackIDs = SplitHull(hullID, k)
    global CellHulls

    oldCOM = CellHulls(hullID).centerOfMass;

    newHulls = Segmentation.ResegmentHull(CellHulls(hullID), k, 1);

    if ( isempty(newHulls) )
        newTrackIDs = [];
        return;
    end
    
    % Mark split hull pieces as user-edited.
    for i=1:length(newHulls)
        newHulls(i).userEdited = true;
    end

    % Drop old graphedits on a manual split
    Tracker.GraphEditsResetHulls(hullID);

    setHullIDs = zeros(1,length(newHulls));
    setHullIDs(1) = hullID;
    % Just arbitrarily assign clone's hull for now
    newHullIDs = Hulls.SetCellHullEntries(setHullIDs, newHulls);
    Editor.LogEdit('Split', hullID, newHullIDs, true);

    newTrackIDs = Tracker.TrackAddedHulls(newHullIDs, oldCOM);
end
