function numFrames = GetNumFrames(fullImageFile)
    numFrames = 0;
    [imagePath imageFile] = fileparts(fullImageFile);
    
    frameIDs = [];
    
    flist = dir(fullfile(imagePath,'*.tif'));
    for i=1:length(flist)
        imgFilePattern = '.+_t(\d+).*\.tif';
        imgFileTokens = regexpi(flist(i).name,imgFilePattern, 'once','tokens');
        if ( isempty(imgFileTokens) )
            continue;
        end
        
        frameIDs = [frameIDs str2double(imgFileTokens{1})];
    end
    
    if ( isempty(frameIDs) )
        return;
    end
    
    numFrames = max(frameIDs);
end
