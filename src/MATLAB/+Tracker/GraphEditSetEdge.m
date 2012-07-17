% GraphEditSetEdge(trackID, nextTrackID, time)
% Set an edge edit in GraphEdits structure.

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

function GraphEditSetEdge(trackID, nextTrackID, time, bLongDistance)
    global GraphEdits CachedCostMatrix CellTracks
    
    if (~exist('bLongDistance','var'))
        bLongDistance = 0;
    end
    
    if(bLongDistance)
        track = CellTracks(trackID);
        if(isempty(track.hulls)) %check for valid track
            trackHull = 0;
        else
            for i=length(track.hulls):-1:1  %search backward through hulls for last edit or first hull
                trackHull = track.hulls(i);
                if(trackHull)
                    if(any(GraphEdits(trackHull,:)) || any(GraphEdits(:,trackHull)))
                        break
                    end
                end
            end
        end
    else
        trackHull = Helper.GetNearestTrackHull(trackID, time-1, -1);
    end
    
    nextHull = Helper.GetNearestTrackHull(nextTrackID, time, 1);
    
    if ( trackHull == 0 || nextHull == 0 )
        return;
    end
    
    GraphEdits(trackHull,:) = 0;
    GraphEdits(:,nextHull) = 0;
    
    GraphEdits(trackHull,nextHull) = 1;
    
    % Update cached cost matrix
    CachedCostMatrix(trackHull,:) = 0;
    CachedCostMatrix(:,nextHull) = 0;
    
    CachedCostMatrix(trackHull,nextHull) = eps;
end

