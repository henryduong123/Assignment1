function bNeedsUpdate = FixMetadata()
    global CONSTANTS
    
    oldFields = {'datasetName'
                 'numChannels'
                 'numFrames'
                 'imageNamePattern'
                 'imageSize'
                 'imageSignificantDigits'};
    
    bNeedsUpdate = false;
    
    for i=1:length(oldFields)
        if ( isfield(CONSTANTS,oldFields{i}) )
            CONSTANTS = rmfield(CONSTANTS,oldFields{i});
            bNeedsUpdate = true;
        end
    end
end