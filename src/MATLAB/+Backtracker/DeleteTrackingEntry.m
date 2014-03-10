function DeleteTrackingEntry(selectedTrackID, dirFlag, time)
    global bDirty
    
    Families.RemoveFromTree(selectedTrackID, time);
    bDirty = true;
end
