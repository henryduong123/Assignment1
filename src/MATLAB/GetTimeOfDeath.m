function tod = GetTimeOfDeath(trackID)
    global CellHulls
    
    tod = [];
    
    [phenotype hullID] = GetTrackPhenotype(trackID);
    
    if ( phenotype ~= 1 )
        return;
    end
    
    tod = CellHulls(hullID).time;
end

