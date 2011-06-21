function GraphEditRemoveEdge(time, parentTrackID, trackID)
    global GraphEdits
    
    parentHull = getNearestPrevHull(time-1, parentTrackID);
    nextHull = getNearestNextHull(time, trackID);
    
    if ( parentHull == 0 || nextHull == 0 )
        return;
    end
    
    GraphEdits(parentHull,nextHull) = -1;
end

function hull = getNearestPrevHull(time, trackID)
    global CellTracks
    
    hull = 0;
    
    hash = time - CellTracks(trackID).startTime + 1;
    if ( hash < 1 || hash > length(CellTracks(trackID).hulls) )
        return;
    end
    
    hull = CellTracks(trackID).hulls(hash);
    if ( hull == 0 )
        hidx = find(CellTracks(trackID).hulls(1:hash),1,'last');
        if ( isempty(hidx) )
            return;
        end
        
        hull = CellTracks(trackID).hulls(hidx);
    end
end

function hull = getNearestNextHull(time, trackID)
	global CellTracks
    
    hull = 0;
    
    hash = time - CellTracks(trackID).startTime + 1;
    if ( hash < 1 || hash > length(CellTracks(trackID).hulls) )
        return;
    end
    
    hull = CellTracks(trackID).hulls(hash);
    if ( hull == 0 )
        hidx = find(CellTracks(trackID).hulls(hash:end),1,'first');
        if ( isempty(hidx) )
            return;
        end
        
        hull = CellTracks(trackID).hulls(hidx);
    end
end