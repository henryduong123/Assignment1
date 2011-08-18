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

% Removes a hull from a track deleting the track if necessary.  If
% bUpdateTree is specified, a track with a significant number of zeros in
% the middle will be split as well.
function [bChangedStart,splitTrack] = RemoveHullFromTrack(hullID, trackID, bUpdateTree, dir)
    global CellTracks CellHulls CellFamilies
    
    if ( ~exist('bUpdateTree', 'var') )
        bUpdateTree = 0;
    end
    
    if ( ~exist('dir', 'var') )
        dir = 1;
    end
    
    if ( isempty(trackID) )
        return;
    end
    
    splitTrack = [];
    bChangedStart = 0;
    
    % Parameters for splitting tracks that have too many continuous zeros
    minLengthSplit = 3;
    minZeroSplit = 3;
    
    % Removes zero hulls from the end of a track and updates endTime
    if ( bUpdateTree )
        RehashCellTracks(trackID,CellTracks(trackID).startTime);
    end
    
    %remove hull from its track
    index = find(CellTracks(trackID).hulls==hullID);
    CellTracks(trackID).hulls(index) = 0;
    
    if(1==index)
        bChangedStart = 1;
        index = find(CellTracks(trackID).hulls,1,'first');
        if(~isempty(index))
            newStartTime = CellHulls(CellTracks(trackID).hulls(index)).time;
            RehashCellTracks(trackID,newStartTime);
            if ( CellFamilies(CellTracks(trackID).familyID).rootTrackID == trackID )
                CellFamilies(CellTracks(trackID).familyID).startTime = newStartTime;
            end
            if ( bUpdateTree && (dir < 0) )
                RemoveFromTree(CellTracks(trackID).startTime, trackID, 'yes');
            end
        else
            if(~isempty(CellTracks(trackID).parentTrack))
                CombineTrackWithParent(CellTracks(trackID).siblingTrack);
            end
            
            childTracks = CellTracks(trackID).childrenTracks;
            for i=1:length(childTracks)
                RemoveFromTree(CellTracks(childTracks(i)).startTime, childTracks(i), 'no');
            end
            
            RemoveTrackFromFamily(trackID);
            ClearTrack(trackID);
        end
    elseif(index==length(CellTracks(trackID).hulls))
        RehashCellTracks(trackID,CellTracks(trackID).startTime);
    elseif ( bUpdateTree && (index > minLengthSplit) )
        % Split track after the removed hull if it hasn't had a hull for too long.
        startchk = max((index-minZeroSplit), 1);
        endchk = min((index+minZeroSplit), length(CellTracks(trackID).hulls));
        if ( all(CellTracks(trackID).hulls(startchk:index) == 0) )
            nzidx = find(CellTracks(trackID).hulls(startchk:end),1);
            nztime = CellTracks(trackID).startTime + nzidx + startchk - 2;
            newFamilyID = RemoveFromTree(nztime, trackID, 'yes');
            if ( isempty(newFamilyID) )
                return;
            end
            
            splitTrack = CellFamilies(newFamilyID).rootTrackID;
            
            StraightenTrack(CellFamilies(newFamilyID).rootTrackID);
            if ( ~isempty(CellTracks(trackID).parentTrack) )
                StraightenTrack(CellTracks(trackID).parentTrack);
            end
        elseif ( all(CellTracks(trackID).hulls(index:endchk) == 0) )
            nzidx = find(CellTracks(trackID).hulls(index:end),1);
            nztime = CellTracks(trackID).startTime + nzidx + index - 2;
            newFamilyID = RemoveFromTree(nztime, trackID, 'yes');
            
            if ( isempty(newFamilyID) )
                return;
            end
            
            splitTrack = CellFamilies(newFamilyID).rootTrackID;
            
            StraightenTrack(CellFamilies(newFamilyID).rootTrackID);
            if ( ~isempty(CellTracks(trackID).parentTrack) )
                StraightenTrack(CellTracks(trackID).parentTrack);
            end
        end
    end
end