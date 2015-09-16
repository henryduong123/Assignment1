function im = LoadPrimaryIntensityImage(frame)
    global CONSTANTS
	primaryChan = CONSTANTS.channelOrder(1);
    
    im = zeros(0,0);
    
    imFilename = Helper.GetFullImagePath(primaryChan, frame);
    if ( ~exist(imFilename,'file') )
        return;
    end
    
    im = Helper.LoadIntensityImage(imFilename);
end
