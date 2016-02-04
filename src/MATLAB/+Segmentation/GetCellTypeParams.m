function segArgs = GetCellTypeParams()
    global CONSTANTS
    
    segArgs = {};
    
    segParams = CONSTANTS.segInfo.params;
    if ( isempty(segParams) )
        return;
    end
    
    segArgs = arrayfun(@(x)(x.value(1)), segParams, 'UniformOutput',0);
end
