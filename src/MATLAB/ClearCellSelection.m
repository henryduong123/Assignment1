function ClearCellSelection()
    global Figures
    
    Figures.cells.selectedHulls = [];
    
    DrawCells();
end