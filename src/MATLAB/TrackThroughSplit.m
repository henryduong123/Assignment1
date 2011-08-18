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

function [costMatrix extendHulls affectedHulls] = TrackThroughSplit(t, newHulls, COM)
    global CONSTANTS CellHulls HashedCells Costs GraphEdits
    
    costMatrix = [];
    extendHulls = [];
    affectedHulls = [];
    
    % Update incoming and outgoing connected-component distance for new hulls
    BuildConnectedDistance(newHulls, 1);
    
    % Add zero costs to cost matrix if necessary
    addCosts = max(max(newHulls)-size(Costs,1),0);
    if (  addCosts > 0 )
        Costs = [Costs zeros(size(Costs,1),addCosts); zeros(addCosts,size(Costs,1)+addCosts)];
        GraphEdits = [GraphEdits zeros(size(GraphEdits,1),addCosts); zeros(addCosts,size(GraphEdits,1)+addCosts)];
    end
    
    if ( t <= 1 )
        return;
    end
    
    curHulls = [HashedCells{t}.hullID];
    lastHulls = [HashedCells{t-1}.hullID];
    
    distSq = sum((vertcat(CellHulls(lastHulls).centerOfMass) - ones(length(lastHulls),1)*COM).^2, 2);
    
    bTrackHull = distSq < ((2*CONSTANTS.dMaxCenterOfMass)^2);
    trackHulls = lastHulls(bTrackHull);
    
    if ( isempty(trackHulls) )
        return;
    end
    
%     oldTracks = [HashedCells{t-1}(bTrackHull).trackID];
    
%     % TODO: don't muck up edited tracks (labels)
%     for i=1:length(oldTracks)
%         hashTime = t - CellTracks(oldTracks(i)).startTime + 1;
%         if ( length(CellTracks(oldTracks(i)).hulls) >= hashTime )
%             CellTracks(oldTracks(i)).hulls(hashTime) = 0;
%         end
%     end

    UpdateTrackingCosts(t-1, trackHulls, newHulls);
    
    [costMatrix, bOutTracked, bInTracked] = GetCostSubmatrix(trackHulls, curHulls);
%     extendTracks = oldTracks(bOutTracked);
    extendHulls = trackHulls(bOutTracked);
    affectedHulls = curHulls(bInTracked);
    
%     % Dump unaffected tracks from the force-keep list
%     affectedTracks = curTracks(bAffected);
%     forceTracks = intersect(forceTracks,
%     union(oldTracks,affectedTracks));
end