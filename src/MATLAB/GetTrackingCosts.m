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

function [costMatrix, trackedHulls, nextHulls] = GetTrackingCosts(windowSize, t, tNext, trackHulls, avoidHulls, hulls, hash, tracks)

    costMatrix = [];
    trackedHulls = [];
    nextHulls = [];
    
    if ( tNext == t )
        return;
    elseif ( tNext-t > 0 )
        dir = 1;
        if ( t+1 > length(hash) )
            return;
        end
    else
        dir = -1;
        if ( t-1 < 1 )
            return;
        end
    end
    
    if ( isempty(trackHulls) )
        error('Unable to track from empty source cell list');
    end
    
    nextFrameHulls = [hash{tNext}.hullID];
    if ( isempty(nextFrameHulls) )
        error('Unable to track to empty destination cell list');
    end
    
    [trackedHulls,rowIdx] = unique(trackHulls,'first');
    [nextHulls,colIdx] = setdiff(nextFrameHulls, avoidHulls);
    
    if ( length(trackedHulls) < length(trackHulls) )
        warning('mexMAT:nonuniqueTrackingList','Non-unique track list, cost matrix will include only unique entries.');
    end
    
    if ( isempty(nextHulls) )
        error('Avoidance constraints caused empty cell list');
    end
    
    endIdx = min(windowSize-1, (length(hash)-t));
    if ( dir < 0 )
        endIdx = min(windowSize-1, tNext);
    end
    
    constraints = cell(1,endIdx+1);
    constraints{1} = trackedHulls;
    constraints{2} = nextHulls;
    
    for i=1:(endIdx-1)
        constraints{i+2} = setdiff([hash{tNext+i*dir}.hullID], avoidHulls);
    end
    
    costMatrix = mexMAT(dir, windowSize, constraints, hulls, hash, tracks);
    
    [dump,backRowIdx] = sort(rowIdx);
    [dump,backColIdx] = sort(colIdx);
    
    costMatrix = costMatrix(backRowIdx,backColIdx);
    trackedHulls = trackedHulls(backRowIdx);
    nextHulls = nextHulls(backColIdx);
end