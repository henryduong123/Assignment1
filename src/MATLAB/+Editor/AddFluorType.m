% [historyAction fluorID] = AddFluorType(description)
% Edit Action:
% 
% Adds a new fluorescence type to the list and updates the fluor type menu.
% NOTE: this is one of the few edit actions that does not directly affect
% undo stack it will always be followed by a ContextSetFluorType action.

function [historyAction fluorID] = AddFluorType(description)
    global FluorTypes
    
    FluorTypes.descriptions = [FluorTypes.descriptions description];
    
    fluorID = length(FluorTypes.descriptions);
    
    UI.UpdateFluorescenceMenu();
    
    historyAction = '';
end
