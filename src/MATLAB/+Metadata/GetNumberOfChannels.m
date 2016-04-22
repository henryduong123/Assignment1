function numChannels = GetNumberOfChannels()
    global CONSTANTS
    
    numChannels = 0;
    if ( ~isfield(CONSTANTS,'imageData') )
        return;
    end
    
    numChannels = CONSTANTS.imageData.NumberOfChannels;
end
