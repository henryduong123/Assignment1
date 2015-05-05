function SetTreeFrozen(treeID, bFrozen)
    global CellFamilies    
    
    CellFamilies(treeID).bFrozen = (bFrozen ~= 0);
    
    Helper.UpdateFrozenCosts(treeID, bFrozen);
end
