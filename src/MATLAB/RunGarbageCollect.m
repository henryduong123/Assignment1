function RunGarbageCollect(currentHull)
    global Figures CellTracks CellFamilies
    
%     currentHull = CellTracks(CellFamilies(Figures.tree.familyID).rootTrackID).hulls(1);
    
    try
        SweepDeleted();
    catch err
        try
            ErrorHandeling(['Garbage Collection -- ' err.message], err.stack);
            return;
        catch err2
            fprintf('%s',err2.message);
            return;
        end
    end
    
    currentTrackID = GetTrackID(currentHull);
    currentFamilyID = CellTracks(currentTrackID).familyID;
    
    Figures.tree.familyID = currentFamilyID;
    
    DrawCells();
    DrawTree(currentFamilyID);
end

