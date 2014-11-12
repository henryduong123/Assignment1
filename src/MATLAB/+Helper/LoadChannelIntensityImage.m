function im = LoadChannelIntensityImage(frame, idx)
    global CONSTANTS
    
    im = zeros(0,0);
    if (idx > numel(CONSTANTS.channelOrder))
        return;
    end
        
	chan = CONSTANTS.channelOrder(idx);
    
    imFilename = Helper.GetFullImagePath(chan, frame);
    if ( ~exist(imFilename,'file') )
        return;
    end
    
    im = Helper.LoadIntensityImage(imFilename);
end
