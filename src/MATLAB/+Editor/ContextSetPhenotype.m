% ContextSetPhenotype(trackID, phenotype, bActive)
% Sets or clears the phenotype specified for the given hull. If the
% phenotype is "dead" there is also some special handling to drop children.

function ContextSetPhenotype(hullID, phenotype, bActive)
    global CellPhenotypes
    
    trackID = Hulls.GetTrackID(hullID);

    try
        % If the phenotype is being set to "dead" then straighten children
        % before setting the phenotype
        if ( ~bActive && phenotype == 1 )
            Tracks.StraightenTrack(trackID);
        end
    catch mexcp
        Error.ErrorHandling(['SetPhenotype(' num2str(hullID) ',' num2str(phenotype) ',' num2str(bActive) ') -- ' mexcp.message], mexcp.stack);
    end

    Tracks.SetPhenotype(hullID, phenotype, bActive);
    Families.ProcessNewborns();
    
    Editor.History('Push');
    if ( bActive )
        Error.LogAction(['Clear phenotype for ' num2str(trackID)]);
    else
        Error.LogAction(['Set phenotype for ' num2str(trackID) ' to ' CellPhenotypes.descriptions{phenotype}]);
    end
end