function RunGarbageCollect(currentHull)
    global Figures CellTracks CellFamilies
    
%     currentHull = CellTracks(CellFamilies(Figures.tree.familyID).rootTrackID).hulls(1);
    
    try
        Helper.SweepDeleted();
    catch err
        Error.ErrorHandling(['Garbage Collection -- ' err.message], err.stack);
        return;
    end
    
    currentTrackID = Hulls.GetTrackID(currentHull);
    currentFamilyID = CellTracks(currentTrackID).familyID;
    
    Figures.tree.familyID = currentFamilyID;
    
    UI.DrawCells();
    UI.DrawTree(currentFamilyID);
end

