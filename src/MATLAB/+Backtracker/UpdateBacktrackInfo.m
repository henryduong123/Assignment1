function UpdateBacktrackInfo()
    global SelectStruct CellTracks
    
    Backtracker.UpdateBacktrackHulls();
    
    newEditTime = 0;
    newEditID = [];
    if ( ~isempty(SelectStruct.editingHullID) )
        newEditID = Hulls.GetTrackID(SelectStruct.editingHullID);
        newEditTime = CellTracks(newEditID).startTime;
    end
    
    Backtracker.SelectTrackingCell(newEditID, newEditTime);
end
