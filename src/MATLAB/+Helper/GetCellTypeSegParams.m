function segArgs = GetCellTypeSegParams(cellType)
    segArgs = {};
    
    typeParams = Load.GetCellTypeParameters(cellType);
    segArgs = {typeParams.segRoutine.params.default};
end