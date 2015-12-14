function imageData = GetImageInfo()
    global CONSTANTS
    
    imageData = [];
    if ( ~isfield(CONSTANTS,'imageData') )
        return;
    end
    
    imageData = CONSTANTS.imageData;
end
