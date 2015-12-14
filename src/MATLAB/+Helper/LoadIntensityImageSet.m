function chanImSet = LoadIntensityImageSet(frame)
    chanImSet = cell(1, Metadata.GetNumberOfChannels());
    
    bAllMissing = true;
    for c = 1:Metadata.GetNumberOfChannels()
        im = Helper.LoadIntensityImage(frame, c);
        if ( isempty(im) )
            continue;
        end
        
        bAllMissing = false;
        chanImSet{c} = im;
    end
    
    if ( bAllMissing )
        chanImSet = {};
    end
end
