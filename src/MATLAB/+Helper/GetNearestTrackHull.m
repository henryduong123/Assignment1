% [hull hullTime] = GetNearestTrackHull(trackID, time, searchDir)
% 
% Search track for a non-zero hull nearest to the specified time, 
% (searchDir < 0) -> search back in time,
% (searchDir > 0) -> search forward in time,
% (searchDir == 0) -> search exact time only.
% returns hull=0 if search fails.

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


function [hull hullTime] = GetNearestTrackHull(trackID, time, searchDir)
    global CellTracks CellHulls
    
    hull = 0;
    hullTime = 0;
    
    hash = time - CellTracks(trackID).startTime + 1;
    if ( hash < 1 && (searchDir > 0) )
        hull = CellTracks(trackID).hulls(1);
        hullTime = CellHulls(hull).time;
        return;
    end
    
    if ( (hash > length(CellTracks(trackID).hulls)) && ((searchDir < 0)) )
        hull = CellTracks(trackID).hulls(end);
        hullTime = CellHulls(hull).time;
        return;
    end
    
    if ( (hash < 1) || (hash > length(CellTracks(trackID).hulls)) )
        return;
    end
    
    hull = CellTracks(trackID).hulls(hash);
    if ( hull > 0 )
        hullTime = CellHulls(hull).time;
        return;
    end
    
    if ( searchDir == 0 )
        return;
    end
    
    if ( searchDir > 0 )
        hidx = find(CellTracks(trackID).hulls(hash:end), 1, 'first') + (hash - 1);
    else
        hidx = find(CellTracks(trackID).hulls(1:hash), 1, 'last');
    end

    if ( isempty(hidx) )
        return;
    end

    hull = CellTracks(trackID).hulls(hidx);
    hullTime = CellHulls(hull).time;
end