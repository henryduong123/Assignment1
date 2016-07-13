% UpdateTrackingCosts.m - Update the tracking costs tracking from trackHulls to nextHulls

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

function UpdateTrackingCosts(t, trackHulls, nextHulls)
    global CellHulls HashedCells CellTracks ConnectedDist
    
    windowSize = 4;
    
    if ( isempty(nextHulls) )
        return;
    end
    
    tNext = CellHulls(nextHulls(1)).time;
    
    if ( isempty(tNext) || tNext > length(HashedCells) || tNext < 1 )
        return;
    end
    
    dir = 1;
    if ( tNext < t )
        dir = -1;
    end
%     trackHulls = checkEditedHistory(windowSize, dir, trackHulls);
    
    trackToHulls = [HashedCells{tNext}.hullID];
    
    avoidHulls = setdiff(trackToHulls,nextHulls);
    %[costMatrix fromHulls toHulls] = TrackingCosts(trackHulls, t, avoidHulls, CellHulls, HashedCells);
    [costMatrix fromHulls toHulls] = Tracker.GetTrackingCosts(windowSize, t, tNext, trackHulls, avoidHulls, CellHulls, HashedCells, CellTracks, ConnectedDist);
    
    % Update newly tracked costs
    if ( dir > 0 )
        Tracker.UpdateCostEdges(costMatrix, fromHulls, toHulls);
    else
        Tracker.UpdateCostEdges((costMatrix'), toHulls, fromHulls);
    end
end

% function trackHulls = checkEditedHistory(windowSize, dir, fromHulls)
%     global CellTracks GraphEdits
%     
%     for i=1:length(fromHulls)
%         
%     end
% end

