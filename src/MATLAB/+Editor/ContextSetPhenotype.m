% historyAction = ContextSetPhenotype(trackID, phenotype, bActive)
% Edit Action:
% 
% Sets or clears the phenotype specified for the given hull. If the
% phenotype is "dead" there is also some special handling to drop children.

function historyAction = ContextSetPhenotype(hullID, phenotype, bActive)
    global CellPhenotypes
    
    trackID = Hulls.GetTrackID(hullID);

    % If the phenotype is being set to "dead" then straighten children
    % before setting the phenotype
    if ( ~bActive && phenotype == 1 )
        Tracks.StraightenTrack(trackID);
    end
    % If the phenotype is being set to "ambiguous" then straighten children
    % before setting the phenotype
    if ( ~bActive && phenotype == 2 )
        Tracks.StraightenTrack(trackID);
    end
        % If the phenotype is being set to "off screen" then straighten children
    % before setting the phenotype
    if ( ~bActive && phenotype == 3)
        Tracks.StraightenTrack(trackID);
    end
    Tracks.SetPhenotype(hullID, phenotype, bActive);
    
    historyAction = 'Push';
end
