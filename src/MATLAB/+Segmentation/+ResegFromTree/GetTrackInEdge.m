function trackEdge = GetTrackInEdge(t, trackID)
    global CellTracks
    
    trackEdge = zeros(1,2);
    
    if ( CellTracks(trackID).startTime > t )
        return;
    end
    
    prevHull = Helper.GetNearestTrackHull(trackID, t-1, -1);
    nextHull = Helper.GetNearestTrackHull(trackID, t, +1);
    
    if ( prevHull == 0 )
        parentTrack = CellTracks(trackID).parentTrack;
        if ( isempty(parentTrack) )
            return
        end
        
        prevHull = CellTracks(parentTrack).hulls(end);
    end
    
    trackEdge = [prevHull nextHull];
end
