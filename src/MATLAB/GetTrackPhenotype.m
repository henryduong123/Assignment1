function [phenotype, hullID] = GetTrackPhenotype(trackID)
    hullID = [];
    phenotype = 0;
    
    [phenotypes hullIDs] = GetAllTrackPhenotypes(trackID);
    
    if ( isempty(phenotypes) )
        return;
    end
    
    hullID = hullIDs(end);
    phenotype = phenotypes(end);
end

