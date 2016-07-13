% [historyAction phenoID] = AddPhenotype(description)
% Edit Action:
% 
% Adds a new phenotype to the list and updates the phenotype menu.
% NOTE: this is one of the few edit actions that does not directly affect
% undo stack it will always be followed by a ContextSetPhenotype action.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
%     Copyright 2016 Drexel University
%
%     This file is part of LEVer - the tool for stem cell lineaging. See
%     http://n2t.net/ark:/87918/d9rp4t for details
% 
%     LEVer is free software: you can redistribute it and/or modify
%     it under the terms of the GNU General Public License as published by
%     the Free Software Foundation, either version 3 of the License, or
%     (at your option) any later version.
% 
%     LEVer is distributed in the hope that it will be useful,
%     but WITHOUT ANY WARRANTY; without even the implied warranty of
%     MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
%     GNU General Public License for more details.
% 
%     You should have received a copy of the GNU General Public License
%     along with LEVer in file "gnu gpl v3.txt".  If not, see 
%     <http://www.gnu.org/licenses/>.
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


function [historyAction phenoID] = AddPhenotype(description)
    global CellPhenotypes Colors
    
    historyAction = '';
    
    if ( isempty(Colors) )
        Colors = Load.CreateColors();
    end
    
    bAlreadyPheno = strcmpi(description,CellPhenotypes.descriptions);
    if ( any(bAlreadyPheno) )
        phenoID = find(bAlreadyPheno,1,'first');
        return;
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
