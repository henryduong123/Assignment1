function numFrames = GetNumberOfFrames()
    global CONSTANTS
    
    numFrames = 0;
    if ( ~isfield(CONSTANTS,'imageData') )
        return;
    end
    
    numFrames = CONSTANTS.imageData.NumberOfFrames;
end
