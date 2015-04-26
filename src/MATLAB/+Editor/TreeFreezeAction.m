% historyAction = TreeFreezeAction(familyID)
% Edit Action:
% 
% Toggles frozen property of familyID

function historyAction = TreeFreezeAction(familyID)
    global CellFamilies
    
    if ( isempty(CellFamilies(familyID).bFrozen) )
        CellFamilies(familyID).bFrozen = false;
    end
    
    bFrozen = CellFamilies(familyID).bFrozen;
    Helper.SetTreeFrozen(familyID, ~bFrozen);

    % Force the tree to lock/unlock with frozen status.
    Helper.SetTreeLocked(familyID,~bFrozen)
    
    historyAction = 'Push';
end