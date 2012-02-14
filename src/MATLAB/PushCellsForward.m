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

function PushCellsForward(pushFamTrack)
    global CellHulls HashedCells CellTracks CellFamilies
    
    tStart = 1;
    tEnd = length(HashedCells);
    
    pushHulls = [];
    for i=1:length(pushFamTrack)
        famID = CellTracks(pushFamTrack(i)).familyID;
        for j=1:length(CellFamilies(famID).tracks)
            trackHulls = CellTracks(CellFamilies(famID).tracks(j)).hulls;
            pushHulls = union(pushHulls, trackHulls(trackHulls > 0));
        end
    end
    
    Progressbar(0);
    for t=tStart:tEnd-1
        trackHulls = [HashedCells{t}.hullID];
        nextHulls = [HashedCells{t+1}.hullID];
        UpdateTrackingCosts(t, trackHulls, nextHulls);
        
        [trackHulls,nextHulls] = CheckGraphEdits(1, trackHulls, nextHulls);
        
        % Missed/Occlusion family-push hulls
        
        [costMatrix,bTrackedHulls,bNextHulls] = GetCostSubmatrix(trackHulls, nextHulls);
        trackedHulls = trackHulls(bTrackedHulls);
        nextHulls = nextHulls(bNextHulls);
        
        costMod = encourageFamilies(pushHulls, costMatrix, trackedHulls);
        costMatrix = costMatrix .* costMod;
        
        bAssign = assignTracks(costMatrix, trackedHulls, nextHulls, 0);
        
        Progressbar((t - tStart + 1)/(tEnd - tStart));
    end
    
    Progressbar(1);
end

function costMod = encourageFamilies(pushHulls, costMatrix, trackHulls)
    global CellFamilies CellTracks
    
    costMod = Inf*ones(size(costMatrix));
    costMod(isfinite(costMatrix)) = 1;
    
%     famTracks = [];
%     for i=1:length(pushFamTracks)
%         famTracks = [famTracks CellFamilies(CellTracks(pushFamTracks(i)).familyID).tracks];
%     end
%     
%     curTracks = GetTrackID(trackHulls);
%     
%     encRows = ismember(curTracks,famTracks);
    encRows = ismember(trackHulls, pushHulls);
    
    costMod(encRows,:) = (10^-3)*costMod(encRows,:);
end

function bAssign = assignTracks(costMatrix, trackedHulls, nextHulls, bPropForward)
    [minInCosts,bestIncoming] = min(costMatrix,[],1);
    [minOutCosts,bestOutgoing] = min(costMatrix,[],2);
    
    bAssign = false(size(costMatrix));
    
    if ( isempty(costMatrix) )
        return;
    end
    
    bestOutgoing  = bestOutgoing';
    bMatchedCol = false(size(bestIncoming));
    bMatched = (bestIncoming(bestOutgoing) == (1:length(bestOutgoing)));
    bMatchedCol(bestOutgoing(bMatched)) = 1;
    matchedIdx = find(bMatched);
    
    % Assign matched edges
    for i=1:length(matchedIdx)
        if ( minOutCosts(matchedIdx(i)) == Inf )
            continue;
        end

        assignHull = nextHulls(bestOutgoing(matchedIdx(i)));
        extHull = trackedHulls(matchedIdx(i));
        
        AssignEdge(extHull, assignHull, bPropForward);
        bAssign(matchedIdx(i), bestOutgoing(matchedIdx(i))) = 1;
    end
end
