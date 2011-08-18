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

% This function is similar to AddHullToTrack but it specifically doesn't
% handle adding hulls before a track start.  Also it orphans child tracks
% if a track is extended past it's mitosis
function ExtendTrackWithHull(trackID, hullID)
    global CellTracks CellFamilies CellHulls

    if ( ~isscalar(hullID) || (hullID <= 0) || (hullID > length(CellHulls)) )
        error('ExtendTrackWithHull - hullID argument must be a valid scalar cell ID');
    end
    
    time = CellHulls(hullID).time;
    hash = time - CellTracks(trackID).startTime + 1;
    if ( hash <= 0 )
        if ( ~isempty(CellTracks(trackID).parentTrack) )
            newFamilyID = RemoveFromTree(CellTracks(trackID).startTime, trackID, 'yes');
            if ( ~isempty(newFamilyID) )
                trackID = CellFamilies(newFamilyID).rootTrackID;
            end
        end
        
        RehashCellTracks(trackID, time);
        CellTracks(trackID).startTime = time;
        hash = time - CellTracks(trackID).startTime + 1;
        if(CellFamilies(CellTracks(trackID).familyID).startTime > time)
            CellFamilies(CellTracks(trackID).familyID).startTime = time;
        end
%         error('ExtendTrackWithHull cannot extend tracks backwards before their start time.');
    end
    
    CellTracks(trackID).hulls(hash) = hullID;

    if ( CellTracks(trackID).endTime < time )
        CellTracks(trackID).endTime = time;
        if(CellFamilies(CellTracks(trackID).familyID).endTime < time)
            CellFamilies(CellTracks(trackID).familyID).endTime = time;
        end
        
        childTracks = CellTracks(trackID).childrenTracks;
        for i=1:length(childTracks)
            % Orphan all children
            RemoveFromTree(CellTracks(childTracks(i)).startTime, childTracks(i), 'no');
        end
    end

    %add the trackID back to HashedHulls
    AddHashedCell(time, hullID, trackID);
end