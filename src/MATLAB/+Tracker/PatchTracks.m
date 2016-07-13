% PatchMatchedTracks()
% Patch together subtrees which may have been orphaned by ChangeLabel
% but are winning matches on the tracking graph. Takes user edits into
% account.

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

function PatchMatchedTracks()
    global CellFamilies CellTracks CellHulls
    
    % Get root hulls of all families
    checkHulls = arrayfun(@getRootHullID, CellFamilies, 'UniformOutput',0);
    checkHulls = [checkHulls{:}];
    
    % Check possible attachments in order of time
    [srtTimes srtIdx] = sort([CellHulls(checkHulls).time]);
    checkHulls = checkHulls(srtIdx);
    
    costMatrix = Tracker.GetCostMatrix();
    
    leafHulls = [];
    for i=1:length(CellFamilies)
        checkTracks = CellFamilies(i).tracks;
        for j=1:length(checkTracks)
            if ( ~isempty(CellTracks(checkTracks(j)).childrenTracks) )
                continue;
            end
            
            endHull = CellTracks(checkTracks(j)).hulls(end);
            leafHulls = [leafHulls endHull];
        end
    end
    
    for i=1:length(checkHulls)
        nzInEdge = find(costMatrix(:,checkHulls(i)));
        
        % Find leaf nodes
        bLeaves = ismember(nzInEdge, leafHulls);
        nzInEdge = nzInEdge(bLeaves);
        [minCost minIdx] = min(costMatrix(nzInEdge));
        if ( isempty(minIdx) )
            continue;
        end

        childTrack = Hulls.GetTrackID(checkHulls(i));
        parentTrack = Hulls.GetTrackID(nzInEdge(minIdx));
        
        if(~isempty(Tracks.GetTimeOfDeath(parentTrack)))
            continue;
        end
        
%         % Check if either child or parent looks like a segmentation error
%         parentScore = GetTrackSegScore(parentTrack);
%         childScore = GetTrackSegScore(childTrack);
%         
%         if ( parentScore < CONSTANTS.minTrackScore || childScore < CONSTANTS.minTrackScore )
%             continue;
%         end
        
        leafHulls = setdiff(leafHulls, nzInEdge(minIdx));
        
        Tracks.ChangeLabel(childTrack, parentTrack);
    end
end

function hullID = getRootHullID(family)
    global CellTracks
    
    if ( isempty(family.startTime) )
        hullID = [];
        return;
    end
    
    hullID = CellTracks(family.rootTrackID).hulls(1);
end

