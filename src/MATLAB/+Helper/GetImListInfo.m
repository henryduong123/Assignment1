function [numChannels numFrames] = GetImListInfo(rootFolder, namePattern)
    numChannels = 0;
    numFrames = 0;
    
    % Generate a directory list glob from namePattern as well as a
    % tokenized set for creating a regexp to match channel and frame numbers
    dirPattern = regexprep(namePattern, '(.*)_c%\d+d_t%\d+d(.+)', '$1_c*_t*$2');
    filePattern = regexp(namePattern, '(.*)_c%0(\d+)d_t%0(\d+)d(.+)', 'tokens', 'once');
    if ( isempty(filePattern) )
        return;
    end
    
    flist = dir(fullfile(rootFolder,dirPattern));
    if ( isempty(flist) )
        return;
    end
    
    matchPrefix = regexptranslate('escape', filePattern{1});
    matchPostfix = regexptranslate('escape', filePattern{4});
    chanDigits = filePattern{2};
    frameDigits = filePattern{3};
    
    matchPattern = [matchPrefix '_c(\d{' chanDigits '})_t(\d{' frameDigits '})' matchPostfix];
    
    fileNames = {flist.name};
    
    matchTok = regexpi(fileNames, matchPattern, 'tokens','once');
    
    times = cellfun(@(x)(str2double(x{2})), matchTok);
    chans = cellfun(@(x)(str2double(x{1})), matchTok);
    
    numChannels = max(chans);
    numFrames = max(times);
end
