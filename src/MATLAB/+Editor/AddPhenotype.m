% [historyAction phenoID] = AddPhenotype(description)
% Edit Action:
% 
% Adds a new phenotype to the list and updates the phenotype menu.
% NOTE: this is one of the few edit actions that does not directly affect
% undo stack it will always be followed by a ContextSetPhenotype action.

function [historyAction phenoID] = AddPhenotype(description)
    global CellPhenotypes Colors
    
    historyAction = '';
    
    if ( isempty(Colors) )
        Load.CreateColors();
    end
    for i=1:length(CellPhenotypes.descriptions)
    if ((strcmpi(description,CellPhenotypes.descriptions{i}))== 1)
        phenoID = i;
        return;
    end
    end
    % Find all colors that haven't been used yet
    phenoColors = vertcat(CellPhenotypes.colors);
    allowedColors = getAllowedColors(phenoColors);
    
    newColorIdx = randi(size(allowedColors,1));
    newPhenoColor = allowedColors(newColorIdx,:);
    
    CellPhenotypes.descriptions = [CellPhenotypes.descriptions description];
    CellPhenotypes.colors = [CellPhenotypes.colors; newPhenoColor];
    
    phenoID = length(CellPhenotypes.descriptions);
    
    UI.UpdatePhenotypeMenu();
end

function [allowedColors bAllowedColors] = getAllowedColors(phenoColors)
    global Colors
    
    if ( isempty(Colors) )
        Load.CreateColors();
    end
    
    bAllowedColors = false(size(Colors,1),1);
    for i=1:size(Colors,1)
        dists = sum((ones(size(phenoColors,1),1)*Colors(i,1:3) - phenoColors).^2, 2);
        minDist = min(dists);
        
        % A dubious threshold, but less than anything in the table
        if ( minDist > (0.1^2) )
            bAllowedColors(i) = 1;
        end
    end
    
    allowedColors = Colors(bAllowedColors, 1:3);
end