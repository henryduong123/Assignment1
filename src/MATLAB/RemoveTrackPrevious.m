%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
%     This file is part of LEVer.exe
%     (C) 2011 Andrew Cohen, Eric Wait and Mark Winter
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function hullIDs = RemoveTrackPrevious(trackID, endHullID)
    global HashedCells CellHulls CellTracks CellFamilies SegmentationEdits
    
    startTime = CellTracks(trackID).startTime;
    endTime = CellTracks(trackID).endTime;
    
    hullIDs = [];
    
    extTime = endTime - CellHulls(endHullID).time;
    if ( extTime > 3 )
        button = questdlg(['This track extends ' num2str(extTime) ' frames past the current frame, are you sure you wish to delete?'], 'Delete Track', 'Yes', 'No', 'Yes');
        if ( strcmpi(button,'No') )
            return;
        end
    end
    
%     rmNum = endTime - startTime + 1;
    
    bNeedsUpdate = 0;
    hulls = CellTracks(trackID).hulls;
    for i=1:length(hulls)
        hullID = hulls(i);
        
        if ( hullID == 0 )
            continue;
        end
        
        hullIDs = [hullIDs hullID];
        
        time = CellHulls(hullID).time;
        bRmUpdate = RemoveHullFromTrack(hullID, trackID);
        hullIdx = [HashedCells{time}.hullID]==hullID;
        
        HashedCells{time}(hullIdx) = [];
        CellHulls(hullID).deleted = 1;
        RemoveSegmentationEdit(hullID,CellHulls(endHullID).time);
        
        bNeedsUpdate = bNeedsUpdate | bRmUpdate;
    end
    
    if ( bNeedsUpdate )
        RemoveFromTree(CellTracks(trackID).startTime, trackID, 'yes');
        ProcessNewborns(1:length(CellFamilies),SegmentationEdits.maxEditedFrame);
    end
end