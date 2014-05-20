function RemoveImagePixelsField()
    global CellHulls
    
    oldCellHulls = CellHulls;
    CellHulls = rmfield(oldCellHulls, 'imagePixels');
end
