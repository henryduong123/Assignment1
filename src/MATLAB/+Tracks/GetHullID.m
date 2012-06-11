function hullID = GetHullID(t, trackID)
    global CellTracks
    
    hullID = 0;
    
    hash = t - CellTracks(trackID).startTime + 1;
    if ( hash < 1 || hash > length(CellTracks(trackID).hulls) )
        return;
    end
    
    hullID = CellTracks(trackID).hulls(hash);
end