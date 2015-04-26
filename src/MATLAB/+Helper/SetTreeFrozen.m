function SetTreeFrozen(treeID, bFrozen)
    global CellFamilies
    
    CellFamilies(treeID).bFrozen = (bFrozen ~= 0);
end
