% PatchMatchedTracks()
% Patch together subtrees which may have been orphaned by ChangeLabel
% but are winning matches on the tracking graph. Takes user edits into
% account.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
%     Copyright 2011-2016 Andrew Cohen
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
    
    bLockedFamilies = [CellFamilies.bLocked];
    unlockedFamilies = find(~bLockedFamilies);
    
    % Get root hulls of all families
    checkHulls = arrayfun(@getRootHullID, unlockedFamilies);
    checkHulls = checkHulls(checkHulls > 0);
    
    % Check possible attachments in order of time
    [srtTimes srtIdx] = sort([CellHulls(checkHulls).time]);
    checkHulls = checkHulls(srtIdx);
    
    costMatrix = Tracker.GetCostMatrix();
    
    leafHulls = [];
    for i=1:length(unlockedFamilies)
        checkTracks = CellFamilies(unlockedFamilies(i)).tracks;
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
        [minCost minIdx] = min(costMatrix(nzInEdge,checkHulls(i)));
        if ( isempty(minIdx) )
            continue;
        end
        
        % Find possible matching track (drop if not a leaf node of family)
        bestInHull = nzInEdge(minIdx);
        if ( ~any(bestInHull == leafHulls) )
            continue;
        end
        
%         nzOutEdge = find(costMatrix(bestInHull,:));
%         [minCost minIdx] = min(costMatrix(bestInHull,nzOutEdge));
%         if ( isempty(minIdx) )
%             continue;
%         end
%         
%         % Check for matching between best in/out edge
%         bestOutHull = nzOutEdge(minIdx);
%         if ( bestOutHull ~= checkHulls(i) )
%             continue;
%         end
        
        childTrack = Hulls.GetTrackID(checkHulls(i));
        parentTrack = Hulls.GetTrackID(bestInHull);
        
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
        
        leafHulls = setdiff(leafHulls, bestInHull);
        
        Tracks.ChangeLabel(childTrack, parentTrack);
    end
end

function hullID = getRootHullID(familyID)
    global CellTracks CellFamilies
    
    hullID = 0;
    if ( isempty(CellFamilies(familyID).startTime) )
        return;
    end
    
    rootTrackID = CellFamilies(familyID).rootTrackID;
    hullID = CellTracks(rootTrackID).hulls(1);
end

