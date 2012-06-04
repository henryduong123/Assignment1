% TrackThroughMerge.m - Retrack and update costs for cells due to a user
% or propagated merge.

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

function [costMatrix extendHulls affectedHulls] = TrackThroughMerge(t, mergeHull)
    global CONSTANTS CellHulls HashedCells
    
    costMatrix = [];
    extendHulls = [];
    affectedHulls = [];
    
    % Update incoming and outgoing connected-component distance for new hulls
    Tracker.BuildConnectedDistance(mergeHull, 1);
    
    if ( t <= 1 )
        return;
    end
    
    curHulls = [HashedCells{t}.hullID];
    lastHulls = [HashedCells{t-1}.hullID];
    
    distSq = sum((vertcat(CellHulls(lastHulls).centerOfMass) - ones(length(lastHulls),1)*CellHulls(mergeHull).centerOfMass).^2, 2);
    
    bTrackHull = distSq < ((2*CONSTANTS.dMaxCenterOfMass)^2);
    trackHulls = lastHulls(bTrackHull);
    
    if ( isempty(trackHulls) )
        return;
    end

    Tracker.UpdateTrackingCosts(t-1, trackHulls, mergeHull);
    
    [costMatrix, bOutTracked, bInTracked] = Tracker.GetCostSubmatrix(trackHulls, curHulls);
    extendHulls = trackHulls(bOutTracked);
    affectedHulls = curHulls(bInTracked);
end