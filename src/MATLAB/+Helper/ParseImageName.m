% [datasetName namePattern] = ParseImageName(imageName)

function [datasetName namePattern] = ParseImageName(imageName)
    datasetName = '';
    namePattern = '';
    
    [filePath fileName fileExt] = fileparts(imageName);
    matchTok = regexpi(fileName, '^(.+_)c(\d+)_t(\d+)$', 'tokens', 'once');
    if ( isempty(matchTok) )
        return;
    end
    
    chanStr = matchTok{1}{2};
    timeStr = matchTok{1}{3};
    
    chanDigits = length(chanStr);
    timeDigits = length(timeStr);
    
    datasetName = matchTok{1}{1};
    namePattern = [datasetName 'c%0' num2str(chanDigits) 'd_t%0' num2str(timeDigits) 'd' fileExt];
end
