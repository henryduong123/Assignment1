function GraphEditRemoveMitosis(removeTrackID)
    global CellTracks GraphEdits
    
    parentTrackID = CellTracks(removeTrackID).parentTrack;
    
    if ( isempty(parentTrackID) )
        return;
    end
    
    parentHull = CellTracks(parentTrackID).hulls(end);
    hull = CellTracks(removeTrackID).hulls(1);
    
    if ( parentHull == 0 || hull == 0 )
        return;
    end
    
    GraphEdits(parentHull, hull) = -1;
end