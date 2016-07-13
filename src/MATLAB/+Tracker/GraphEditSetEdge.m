% GraphEditSetEdge(trackID, nextTrackID, time)
% 
% Set an edge edit in GraphEdits structure.

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

function GraphEditSetEdge(trackID, nextTrackID, time, bLongDistance)
    global GraphEdits CachedCostMatrix CellTracks
    
    if (~exist('bLongDistance','var'))
        bLongDistance = 0;
    end
    
    [trackHull hullTime] = Helper.GetNearestTrackHull(trackID, time-1, -1);
    if ( trackHull == 0 )
        return;
    end
    
    if(bLongDistance)
        hash = hullTime - CellTracks(trackID).startTime + 1;
        if ( hash < 1 )
            return;
        end
        
        trackHulls = CellTracks(trackID).hulls(1:hash);
        nzHulls = trackHulls(trackHulls > 0);
        if ( isempty(nzHulls) )
            return;
        end
        
        trackHullIdx = find(any(GraphEdits(:,nzHulls),1),1,'last');
        if ( isempty(trackHullIdx) )
            trackHull = CellTracks(trackID).hulls(1);
        else
            trackHull = nzHulls(trackHullIdx);
        end
    end
    
    nextHull = Helper.GetNearestTrackHull(nextTrackID, time, 1);
    
    if ( trackHull == 0 || nextHull == 0 )
        return;
    end
    
    Editor.LogEdit('SetEdge', trackHull,nextHull,true);
    
    GraphEdits(trackHull,:) = 0;
    GraphEdits(:,nextHull) = 0;
    
    GraphEdits(trackHull,nextHull) = 1;
    
    % Update cached cost matrix
    CachedCostMatrix(trackHull,:) = 0;
    CachedCostMatrix(:,nextHull) = 0;
    
    CachedCostMatrix(trackHull,nextHull) = eps;
end

