function newTrackID = TearoffHull(trackID, time)
    global CellTracks
    
    hullID = Tracks.GetHullID(time, trackID);
    
    if ( length(CellTracks(trackID).hulls) == 1 )
        newTrackID = trackID;
        return;
    end
    
    bLeafTrack = isempty(CellTracks(trackID).childrenTracks);
    
    bStartHull = (CellTracks(trackID).startTime == time);
    bEndHull = (CellTracks(trackID).endTime == time);
    
    droppedTracks = Families.RemoveFromTree(trackID, time);
    
    newTrackID = Hulls.GetTrackID(hullID);
    if ( bEndHull )
        % Tearoff both children since can't reconstruct mitosis without
        % this hull
        if ( ~bLeafTrack )
            Families.RemoveFromTreePrune(CellTracks(trackID).childrenTracks(1));
        end
        return;
    end
    
    % Tearoff rest of subtree if this is root or the start of a track
    % (can't reattach mitosis events without a new hull)
    if ( bStartHull )
        Families.RemoveFromTreePrune(newTrackID,time+1);
    	return;
    end
    
    % Reattach the rest of the track
    Tracks.ChangeLabel(newTrackID, trackID, time+1);
end
