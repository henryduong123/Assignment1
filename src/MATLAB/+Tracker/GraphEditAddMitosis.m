% GraphEditAddMitosis(trackID, siblingTrackID, time)
% Add edges to GraphEdits structure for a user specified mitosis.

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

function GraphEditAddMitosis(trackID, siblingTrackID, time)
    global GraphEdits Costs CachedCostMatrix
    
    parentHull = Helper.GetNearestTrackHull(trackID, time-1, 0);
    
    childHull = Helper.GetNearestTrackHull(trackID, time, 0);
    siblingHull = Helper.GetNearestTrackHull(siblingTrackID, time, 0);
    
    if ( parentHull == 0 || childHull == 0 || siblingHull == 0 )
        return;
    end
    
    GraphEdits(parentHull,:) = 0;
    GraphEdits(:,childHull) = 0;
    GraphEdits(:,siblingHull) = 0;
    
    cChild = Costs(parentHull,childHull);
    if ( cChild == 0 )
        cChild = Inf;
    end
    
    cSibling = Costs(parentHull,siblingHull);
    if ( cSibling == 0 )
        cSibling = Inf;
    end
    
    if ( cChild < cSibling )
        GraphEdits(parentHull,childHull) = 1;
        GraphEdits(parentHull,siblingHull) = 2;
    else
        GraphEdits(parentHull,childHull) = 2;
        GraphEdits(parentHull,siblingHull) = 1;
    end
    
    % Also update cached cost matrix
    CachedCostMatrix(parentHull,:) = 0;
    CachedCostMatrix(:,childHull) = 0;
    CachedCostMatrix(:,siblingHull) = 0;
    
    CachedCostMatrix(parentHull,childHull) = eps * GraphEdits(parentHull,childHull);
    CachedCostMatrix(parentHull,siblingHull) = eps * GraphEdits(parentHull,siblingHull);
end
