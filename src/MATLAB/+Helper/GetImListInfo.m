function [numChannels numFrames] = GetImListInfo(rootFolder, namePattern)
    numChannels = 0;
    numFrames = 0;
    
    % Generate a directory list glob from namePattern as well as a
    % tokenized set for creating a regexp to match channel and frame numbers
    [prefixString paramTokens postfixString] = Helper.SplitNamePattern(namePattern);
    if ( isempty(prefixString) )
        return;
    end
    
    paramGlobs = cellfun(@(x)(['_' x{1} '*']),paramTokens, 'UniformOutput',0);
    dirPattern = [prefixString paramGlobs{:}  postfixString];
    
    flist = dir(fullfile(rootFolder,dirPattern));
    if ( isempty(flist) )
        return;
    end
    
    matchPrefix = regexptranslate('escape', prefixString);
    matchPostfix = regexptranslate('escape', postfixString);
    paramPatterns = cellfun(@(x)(['_' x{1} '(\d{' x{2} '})']),paramTokens, 'UniformOutput',0);
    
    matchPattern = [matchPrefix paramPatterns{:} matchPostfix];
    
    fileNames = {flist.name};
    matchTok = regexpi(fileNames, matchPattern, 'tokens','once');
    
    paramOrder = cellfun(@(x)(x{1}),paramTokens, 'UniformOutput',0);
    assumedParams = {'c' 't' 'z'};
    [bHasParam,paramIdx] = ismember(assumedParams, paramOrder);
    
    numChannels = 1;
    numFrames = 1;
    numZStack = 1;
    
    if ( bHasParam(1) )
        chans = cellfun(@(x)(str2double(x{paramIdx(1)})), matchTok);
        numChannels = max(chans);
    end
    
    if ( bHasParam(2) )
        times = cellfun(@(x)(str2double(x{paramIdx(2)})), matchTok);
        numFrames = max(times);
    end
end
