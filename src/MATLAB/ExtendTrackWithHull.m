% This function is similar to AddHullToTrack but it specifically doesn't
% handle adding hulls before a track start.  Also it orphans child tracks
% if a track is extended past it's mitosis
function ExtendTrackWithHull(trackID, hullID)
    global CellTracks CellFamilies CellHulls

    time = CellHulls(hullID).time;
    hash = time - CellTracks(trackID).startTime + 1;
    if ( hash <= 0 )
        error('ExtendTrackWithHull cannot extend tracks backwards before their start time.');
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