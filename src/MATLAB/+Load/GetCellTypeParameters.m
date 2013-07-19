function typeParams = GetCellTypeParameters(cellType)
    typeParams = [];
    cellTypes = Load.GetSupportedCellTypes();
    
    typeNames = {cellTypes.name};
    idx = find(strcmpi(typeNames, cellType));
    
    if ( ~isempty(idx) )
        typeParams = cellTypes(idx);
    end
    
end