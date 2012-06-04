% RemoveTrackPrevious.m - Remove all segmentations on the current track.

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

function hullIDs = RemoveTrackPrevious(trackID, endHullID)
    global HashedCells CellHulls CellTracks CellFamilies SegmentationEdits
    
    startTime = CellTracks(trackID).startTime;
    endTime = CellTracks(trackID).endTime;
    
    hullIDs = [];
    
    extTime = endTime - CellHulls(endHullID).time;
    if ( extTime > 3 )
        button = questdlg(['This track extends ' num2str(extTime) ' frames past the current frame, are you sure you wish to delete?'], 'Delete Track', 'Yes', 'No', 'Yes');
        if ( strcmpi(button,'No') )
            return;
        end
    end
    
    bNeedsUpdate = 0;
    hulls = CellTracks(trackID).hulls;
    for i=1:length(hulls)
        hullID = hulls(i);
        
        if ( hullID == 0 )
            continue;
        end
        
        hullIDs = [hullIDs hullID];
        
        time = CellHulls(hullID).time;
        %TODO Fix func call
        bRmUpdate = Tracks.RemoveHullFromTrack(hullID, trackID);
        hullIdx = [HashedCells{time}.hullID]==hullID;
        
        HashedCells{time}(hullIdx) = [];
        CellHulls(hullID).deleted = 1;
        Segmentation.RemoveSegmentationEdit(hullID,CellHulls(endHullID).time);
        
        bNeedsUpdate = bNeedsUpdate | bRmUpdate;
    end
    
    if ( bNeedsUpdate )
        %TODO fix func call
        Families.RemoveFromTree(CellTracks(trackID).startTime, trackID, 'yes');
        Families.ProcessNewborns(1:length(CellFamilies),SegmentationEdits.maxEditedFrame);
    end
end