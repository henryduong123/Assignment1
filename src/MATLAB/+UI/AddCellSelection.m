function AddCellSelection(hullID)
    global Figures
    
    bAlreadySelected = (Figures.cells.selectedHulls == hullID);
    if ( any(bAlreadySelected) )
        return;
    end
    
    Figures.cells.selectedHulls = [Figures.cells.selectedHulls hullID];
end
