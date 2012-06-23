% [historyAction phenoID] = AddPhenotype(description)
% Edit Action:
% 
% Adds a new phenotype to the list and updates the phenotype menu.
% NOTE: this is one of the few edit actions that does not directly affect
% undo stack it will always be followed by a ContextSetPhenotype action.

function [historyAction phenoID] = AddPhenotype(description)
    global CellPhenotypes
    
    CellPhenotypes.descriptions = [CellPhenotypes.descriptions description];
    
    phenoID = length(CellPhenotypes.descriptions);
    
    UI.UpdatePhenotypeMenu();
    
    historyAction = '';
end
