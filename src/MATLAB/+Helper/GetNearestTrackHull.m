% [hull hullTime] = GetNearestTrackHull(trackID, time, searchDir)
% Search track for a non-zero hull nearest to the specified time, searchDir
% beack in time if searchDir < 0 or forward if searchDir > 0. Returns 0 if
% no hull exists in specified direction.

function [hull hullTime] = GetNearestTrackHull(trackID, time, searchDir)
    global CellTracks CellHulls
    
    hull = 0;
    hullTime = 0;
    
    hash = time - CellTracks(trackID).startTime + 1;
    if ( hash < 1 && (searchDir >= 0) )
        hull = CellTracks(trackID).hulls(1);
        hullTime = CellHulls(hull).time;
        return;
    end
    
    if ( (hash > length(CellTracks(trackID).hulls)) && ((searchDir < 0)) )
        hull = CellTracks(trackID).hulls(end);
        hullTime = CellHulls(hull).time;
        return;
    end
    
    if ( (hash < 1) || (hash > length(CellTracks(trackID).hulls)) )
        return;
    end
    
    hull = CellTracks(trackID).hulls(hash);
    if ( hull == 0 )
        if ( searchDir >= 0 )
            hidx = find(CellTracks(trackID).hulls(hash:end), 1, 'first') + (hash - 1);
        else
            hidx = find(CellTracks(trackID).hulls(1:hash), 1, 'last');
        end
        
        if ( isempty(hidx) )
            return;
        end
        
        hull = CellTracks(trackID).hulls(hidx);
        hullTime = CellHulls(hull).time;
    end
end