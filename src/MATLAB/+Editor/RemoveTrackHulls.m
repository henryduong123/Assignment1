% [historyAction droppedTracks] = RemoveTrackHulls(trackID)
% Edit Action:
% 
% Remove all segmentations on the current track.

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

function [historyAction droppedTracks] = RemoveTrackHulls(trackID)
    global CellTracks
    
    droppedTracks = [];
    
    Families.RemoveFromTree(trackID);
    
    hulls = CellTracks(trackID).hulls;
    
    for i=1:length(hulls)
        if ( hulls(i) == 0 )
            continue;
        end
        
        Segmentation.RemoveSegmentationEdit(hulls(i));
        droppedTracks = [droppedTracks Hulls.RemoveHull(hulls(i))];
    end
    
    historyAction = 'Push';
end
