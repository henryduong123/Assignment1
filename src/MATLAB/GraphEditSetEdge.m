%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
%     This file is part of LEVer.exe
%     (C) 2011 Andrew Cohen, Eric Wait and Mark Winter
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function GraphEditSetEdge(time, trackID, nextTrackID)
    global GraphEdits
    
    trackHull = getNearestPrevHull(time-1, trackID);
    nextHull = getNearestNextHull(time, nextTrackID);
    
    if ( trackHull == 0 || nextHull == 0 )
        return;
    end
    
    GraphEdits(trackHull,:) = 0;
    GraphEdits(:,nextHull) = 0;
    
    GraphEdits(trackHull,nextHull) = 1;
end

function hull = getNearestPrevHull(time, trackID)
    global CellTracks
    
    hull = 0;
    
    hash = time - CellTracks(trackID).startTime + 1;
    if ( hash < 1 )
        return;
    end
    
    if ( hash > length(CellTracks(trackID).hulls) )
        hash = length(CellTracks(trackID).hulls);
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
    if ( hash > length(CellTracks(trackID).hulls) )
        return;
    end
    
    if ( hash < 1 )
        
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