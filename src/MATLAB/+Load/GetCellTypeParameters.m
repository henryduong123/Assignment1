function typeParams = GetCellTypeParameters(cellType)
    typeParams = struct('name',{}, 'segParams',{}, 'trackParams',{});
    cellTypes = Load.GetSupportedCellTypes();
    
    typeNames = {cellTypes.name};
    idx = find(strcmpi(typeNames, cellType));
    
    if ( ~isempty(idx) )
        typeParams = cellTypes(idx);
    end
    
end