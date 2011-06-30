%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
%     This file is part of LEVer.exe
%     (C) 2011 Andrew Cohen, Eric Wait and Mark Winter
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function bNeedsUpdate = FixOldFileVersions(currentVersion)
    global CellHulls ConnectedDist GraphEdits Costs CellPhenotypes CellTracks

    bNeedsUpdate = 0;
    
    % Add imagePixels field to CellHulls structure (and resave in place)
    if ( ~isfield(CellHulls, 'imagePixels') )
        fprintf('\nAdding Image Pixel Information...\n');
        AddImagePixelsField();
        fprintf('Image Information Added\n');
        bNeedsUpdate = 1;
    end
    
    % Need userEdited field as of ver 5.0
    if ( ~isfield(CellHulls, 'userEdited') )
        AddUserEditedField();
        bNeedsUpdate = 1;
    end
    
    if ( isempty(GraphEdits) )
        GraphEdits = sparse([], [], [], size(Costs,1), size(Costs,2), round(0.1*size(Costs,2)));
        bNeedsUpdate = 1;
    end

    % Calculate connected-component distance for all cell hulls (out 2 frames)
    if ( ~CheckFileVersionString('4.3') || isempty(ConnectedDist) )
        fprintf('\nBuilding Cell Distance Information...\n');
        ConnectedDist = [];
        BuildConnectedDistance(1:length(CellHulls), 0, 1);
        fprintf('Finished\n');
        bNeedsUpdate = 1;
    end
    
    % Remove CellTracks.phenotype field and use it to create hullPhenoSet
    % instead
    if ( ~CheckFileVersionString('5.0') || (~isfield(CellPhenotypes,'hullPhenoSet') && isfield(CellTracks,'phenotype') && isfield(CellTracks,'timeOfDeath')) )
        fprintf('\nConverting Phenotype information...\n');
        UpdatePhenotypeInfo();
        fprintf('Finished\n');
        bNeedsUpdate = 1;
    end
end