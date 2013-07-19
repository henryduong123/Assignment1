function typeParams = GetCellTypeParameters(cellType)
    typeParams = struct('name',{[]}, 'segParams',{[]}, 'trackParams',{[]}, 'leverParams',{[]});
    cellTypes = Load.GetSupportedCellTypes(typeParams);
    
    typeNames = {cellTypes.name};
    idx = find(strcmpi(typeNames, cellType));
    
    if ( ~isempty(idx) )
        typeParams = cellTypes(idx);
    end
    
end