% Removes a hull from a track deleting the track if necessary.  If
% bUpdateTree is specified, a track with a significant number of zeros in
% the middle will be split as well.
function RemoveHullFromTrack(hullID, trackID, bUpdateTree)
    global CellTracks CellHulls CellFamilies
    
    if ( ~exist('bUpdateTree', 'var') )
        bUpdateTree = 0;
    end
    
    if ( isempty(trackID) )
        return;
    end
    
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
        index = find(CellTracks(trackID).hulls,1,'first');
        if(~isempty(index))
            RehashCellTracks(trackID,CellHulls(CellTracks(trackID).hulls(index)).time);
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
        if ( all(CellTracks(trackID).hulls(startchk:index) == 0) )
            nzidx = find(CellTracks(trackID).hulls(startchk:end),1);
            nztime = CellTracks(trackID).startTime + nzidx + startchk - 2;
            newFamilyID = RemoveFromTree(nztime, trackID, 'yes');
            
            StraightenTrack(CellFamilies(newFamilyID).rootTrackID);
            if ( ~isempty(CellTracks(trackID).parentTrack) )
                StraightenTrack(CellTracks(trackID).parentTrack);
            end
        end
    end
end