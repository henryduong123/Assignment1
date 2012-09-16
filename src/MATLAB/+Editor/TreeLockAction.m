% historyAction = TreeLockAction(familyID)
% Edit Action:
% 
% Toggles lock on familyID

function historyAction = TreeLockAction(familyID)
    global CellFamilies
    
    bIsLocked = CellFamilies(familyID).bLocked;
    CellFamilies(familyID).bLocked = ~bIsLocked;
    
    historyAction = 'Push';
end