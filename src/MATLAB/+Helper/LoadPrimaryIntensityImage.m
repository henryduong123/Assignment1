function im = LoadPrimaryIntensityImage(frame)
    global CONSTANTS
	primaryChan = CONSTANTS.primaryChannel;
    
    im = Helper.LoadIntensityImage(frame, primaryChan);
end
