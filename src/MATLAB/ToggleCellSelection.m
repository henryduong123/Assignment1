function ToggleCellSelection(cellID)
    global Figures
    
    bAlreadySelected = (Figures.cells.selectedHulls == cellID);
    if ( any(bAlreadySelected) )
        Figures.cells.selectedHulls = Figures.cells.selectedHulls(~bAlreadySelected);
    else
        Figures.cells.selectedHulls = [Figures.cells.selectedHulls cellID];
    end
    
    DrawCells();
end