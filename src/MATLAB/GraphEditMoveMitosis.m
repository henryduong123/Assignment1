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

function GraphEditMoveMitosis(time, trackID)
    global CellTracks GraphEdits
    
    parentTrackID = CellTracks(trackID).parentTrack;
    siblingTrackID = CellTracks(trackID).siblingTrack;
    
    if ( isempty(parentTrackID) || isempty(siblingTrackID) )
        return;
    end
    
    siblingHull = getNearestNextHull(CellTracks(siblingTrackID).startTime, trackID);
    newChildHull = getNearestNextHull(time, parentTrackID);
    newParentHull = getNearestPrevHull(time-1, parentTrackID);
    
    if ( siblingHull == 0 || newChildHull == 0 || newParentHull == 0 )
        return;
    end
    
    GraphEdits(newParentHull,:) = 0;
    GraphEdits(:,newChildHull) = 0;
    GraphEdits(:,siblingHull) = 0;
    
    GraphEdits(newParentHull,newChildHull) = 1;
    GraphEdits(newParentHull,siblingHull) = 1;
end

function hull = getNearestPrevHull(time, trackID)
    global CellTracks
    
    hull = 0;
    
    hash = time - CellTracks(trackID).startTime + 1;
    if ( hash < 1 || hash > length(CellTracks(trackID).hulls) )
        return;
    end
    
    hull = CellTracks(trackID).hulls(hash);
    if ( hull == 0 )
        hidx = find(CellTracks(trackID).hulls(1:hash),1,'last');
        if ( isempty(hidx) )
            return;
        end
        
        hull = CellTracks(trackID).hulls(hidx);
    end
end

function hull = getNearestNextHull(time, trackID)
	global CellTracks
    
    hull = 0;
    
    hash = time - CellTracks(trackID).startTime + 1;
    if ( hash < 1 || hash > length(CellTracks(trackID).hulls) )
        return;
    end
    
    hull = CellTracks(trackID).hulls(hash);
    if ( hull == 0 )
        hidx = find(CellTracks(trackID).hulls(hash:end),1,'first');
        if ( isempty(hidx) )
            return;
        end
        
        hull = CellTracks(trackID).hulls(hidx);
    end
end