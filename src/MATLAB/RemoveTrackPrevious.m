%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
%     This file is part of LEVer.exe
%     (C) 2011 Andrew Cohen, Eric Wait and Mark Winter
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function hullIDs = RemoveTrackPrevious(trackID, endHullID)
    global HashedCells CellHulls CellTracks
    
    startTime = CellTracks(trackID).startTime;
    endTime = CellHulls(endHullID).time;
    
    rmNum = endTime - startTime + 1;
    
    hullIDs = [];
    bNeedsUpdate = 0;
    hulls = CellTracks(trackID).hulls;
    for i=1:rmNum
        hullID = hulls(i);
        time = startTime + i - 1;
        
        if ( hullID == 0 )
            continue;
        end
        
        hullIDs = [hullIDs hullID];
        
        bRmUpdate = RemoveHullFromTrack(hullID, trackID);
        hullIdx = [HashedCells{time}.hullID]==hullID;
        
        HashedCells{time}(hullIdx) = [];
        CellHulls(hullID).deleted = 1;
        RemoveSegmentationEdit(hullID);
        
        bNeedsUpdate = bNeedsUpdate | bRmUpdate;
    end
    
    if ( bNeedsUpdate )
        RemoveFromTree(CellTracks(trackID).startTime, trackID, 'yes');
        ProcessNewborns();
    end
end