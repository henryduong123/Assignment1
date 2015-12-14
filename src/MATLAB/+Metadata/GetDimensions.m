function dims = GetDimensions(dimOrder)
    global CONSTANTS
    
    if ( ~exist('dimOrder','var') )
        dimOrder = 'xy';
    end
    
    dims = [];
    selectedDims = [1 2 3];
    if ( strcmpi(dimOrder,'rc') )
        selectedDims = [2 1 3];
    end
    
    if ( ~isfield(CONSTANTS,'imageData') )
        return;
    end
    
    dims = CONSTANTS.imageData.Dimensions(selectedDims);
end
