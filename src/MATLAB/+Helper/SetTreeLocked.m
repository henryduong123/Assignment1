
function SetTreeLocked(treeID, bLocked)
    global CellFamilies
    
    CellFamilies(treeID).bLocked = (bLocked ~= 0);
end
