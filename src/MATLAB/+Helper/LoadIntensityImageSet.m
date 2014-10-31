function chanImSet = LoadIntensityImageSet(frame)
    global CONSTANTS
    
    chanImSet = cell(1,CONSTANTS.numChannels);
    
    bAllMissing = true;
    for c = 1:CONSTANTS.numChannels
        imFilename = Helper.GetFullImagePath(c, frame);
        if ( ~exist(imFilename,'file') )
            continue;
        end
        
        bAllMissing = false;
        chanImSet{c} = Helper.LoadIntensityImage(imFilename);
    end
    
    if ( bAllMissing )
        chanImSet = {};
    end
end
