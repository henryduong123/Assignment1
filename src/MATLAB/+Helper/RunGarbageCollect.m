function RunGarbageCollect(currentHull)
    global Figures CellTracks CellFamilies
    
%     currentHull = CellTracks(CellFamilies(Figures.tree.familyID).rootTrackID).hulls(1);
    
    try
        Helper.SweepDeleted();
    catch err
        try
            Error.ErrorHandeling(['Garbage Collection -- ' err.message], err.stack);
            return;
        catch err2
            fprintf('%s',err2.message);
            return;
        end
    end
    
    currentTrackID = Tracks.GetTrackID(currentHull);
    currentFamilyID = CellTracks(currentTrackID).familyID;
    
    Figures.tree.familyID = currentFamilyID;
    
    UI.DrawCells();
    UI.DrawTree(currentFamilyID);
end

