function trackSegScore = GetTrackSegScore(trackID)
    global CellTracks CellFeatures
    
    % If CellFeatures doesn't exist then always scores 1.0
    if ( isempty(CellFeatures) )
        trackSegScore = 1.0;
        return;
    end
    
    hulls = CellTracks(trackID).hulls(CellTracks(trackID).hulls > 0);
    bDark = [CellFeatures(hulls).brightInterior] == 0;
    hulls = hulls(bDark);
    
    igRatio = [CellFeatures(hulls).igRatio];
    darkRatio = [CellFeatures(hulls).darkRatio];
    
    trackSegScore = median(igRatio .* darkRatio);
end