function typeParams = GetCellTypeParameters(cellType)
    typeParams = [];
    cellTypes = Load.GetSupportedCellTypes();
    
    typeNames = {cellTypes.name};
    idx = find(strcmpi(typeNames, cellType));
    
    if ( isempty(idx) )
        error([cellType ' is not a supported cell type.']);
    end
    
    typeParams = cellTypes(idx);
end
