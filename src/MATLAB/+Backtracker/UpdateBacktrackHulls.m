function UpdateBacktrackHulls()
    global CellTracks CellFamilies BackTrackIdx BackSelectHulls
    
    hullTracks = unique(Hulls.GetTrackID(BackSelectHulls));
    familyIDs = unique([CellTracks(hullTracks).familyID]);
    BackTrackIdx = [CellFamilies(familyIDs).tracks];
end
