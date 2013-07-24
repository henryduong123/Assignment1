% historyAction = TreeLockAction(familyID)
% Edit Action:
% 
% Toggles lock on familyID

function historyAction = TreeLockAction(familyID)
    global CellFamilies
    
    if ( isempty(CellFamilies(familyID).bLocked) )
        CellFamilies(familyID).bLocked = 0;
    end
    
    bIsLocked = CellFamilies(familyID).bLocked;
    Helper.SetTreeLocked(familyID, ~bIsLocked);
    
    historyAction = 'Push';
end