function dims = GetDimensions(dimOrder)
    global CONSTANTS
    
    if ( ~exist('dimOrder','var') )
        dimOrder = 'xy';
    end
    
    dims = [];
    if ( ~isfield(CONSTANTS,'imageData') )
        return;
    end
    
    numDims = 3;
    if ( CONSTANTS.imageData.Dimensions(3) == 1 )
        numDims = 2;
    end
    
    selectedDims = 1:numDims;
    if ( strcmpi(dimOrder,'rc') )
        selectedDims = Utils.SwapXY_RC(selectedDims);
    end
    
    dims = CONSTANTS.imageData.Dimensions(selectedDims);
end
