function pixelSize = GetPixelSize()
    global CONSTANTS
    
    pixelSize = 0;
    if ( ~isfield(CONSTANTS,'imageData') )
        return;
    end
    
    pixelSize = CONSTANTS.imageData.PixelPhysicalSize;
end
