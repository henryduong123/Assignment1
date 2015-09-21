function segArgs = GetCellTypeSegParams(cellType)
    segArgs = {};
    
    typeParams = Load.GetCellTypeParameters(cellType);
    
    segParams = {typeParams.segRoutine.params};
    if ( isempty(segParams) )
        return;
    end
    
    segArgs = cellfun(@(x)(x.value(1)), segParams, 'UniformOutput',0);
end