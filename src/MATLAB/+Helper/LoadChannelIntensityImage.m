function im = LoadChannelIntensityImage(frame, chanIdx)
    global CONSTANTS
    
    im = zeros(0,0);
    if (chanIdx > CONSTANTS.numChannels)
        return;
    end
    
    imFilename = Helper.GetFullImagePath(chanIdx, frame);
    if ( ~exist(imFilename,'file') )
        return;
    end
    
    im = Helper.LoadIntensityImage(imFilename);
end
