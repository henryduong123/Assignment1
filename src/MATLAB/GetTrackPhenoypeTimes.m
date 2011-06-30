function t = GetTrackPhenoypeTimes(trackID)
    global CellHulls
    
    t = [];
    
    [phenotypes hullIDs] = GetAllTrackPhenotypes(trackID);
    
    if ( isempty(phenotypes) )
        return;
    end
    
    t = [CellHulls(hullIDs).time];
end



