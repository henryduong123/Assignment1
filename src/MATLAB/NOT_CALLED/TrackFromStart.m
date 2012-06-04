function TrackFromStart()
    global CellFamilies
    
    trackList = [];
    for i=1:length(CellFamilies)
        if ( CellFamilies(i).startTime > 1 )
            continue;
        end
        
        trackList = [trackList CellFamilies(i).rootTrackID];
    end
    
    TrackCellsForward(trackList);
    
    UI.History('Push');
end