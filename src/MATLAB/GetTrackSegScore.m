function trackSegScore = GetTrackSegScore(trackID)
    global CellTracks CellFeatures
    
    hulls = CellTracks(trackID).hulls(CellTracks(trackID).hulls > 0);
    bDark = [CellFeatures(hulls).brightInterior] == 0;
    hulls = hulls(bDark);
    
    igRatio = [CellFeatures(hulls).igRatio];
    darkRatio = [CellFeatures(hulls).darkRatio];
    
    trackSegScore = median(igRatio .* darkRatio);
end