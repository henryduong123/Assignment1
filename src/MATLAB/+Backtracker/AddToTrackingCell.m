function newTrackID = AddToTrackingCell(trackID, dirFlag, time, point)
    global bDirty CellFamilies EditFamIdx BackTrackIdx
    
    bDirty = true;
    
    newTrackID = [];
    hullID = Hulls.FindHull(time, point);
    if ( hullID > 0 )
        curTrackID = Hulls.GetTrackID(hullID);
    else
        curTrackID = Backtracker.AddSegmentHull(point, time);
    end
    
    editTracks = [CellFamilies(EditFamIdx).tracks BackTrackIdx];
    
    bClickEdited = any(curTrackID == editTracks);
    if ( ~bClickEdited )
        curTrackID = Backtracker.TearoffHull(curTrackID, time);
    end
    
    if ( trackID <= 0 )
        % Create or set new tracking cell
        newTrackID = curTrackID;
        Backtracker.UpdateBacktrackInfo();
        return;
    end
    
    if ( dirFlag < 0 )
        Tracks.ChangeLabel(trackID, curTrackID, time+1);
    else
        Tracks.ChangeLabel(curTrackID, trackID, time);
    end
    
    Backtracker.UpdateBacktrackInfo();
end
