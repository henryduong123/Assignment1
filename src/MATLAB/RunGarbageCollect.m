function RunGarbageCollect(currentHull)
    global Figures CellTracks
    
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
    
    trackID = GetTrackID(currentHull);
    
    DrawCells();
    DrawTree(CellTracks(trackID).familyID);
end

