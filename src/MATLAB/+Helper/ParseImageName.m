% [datasetName namePattern] = ParseImageName(imageName)

function [datasetName namePattern] = ParseImageName(imageName)
    datasetName = '';
    namePattern = '';
    
    supportedPatterns = {%'^(.+)_(c\d+)_(t\d+)_(z\d+)(.*)$';
                         '^(.+)_(c\d+)_(t\d+)(.*)$';
                         '^(.+)_(t\d+)(.*)$'};
    
    [filePath fileName fileExt] = fileparts(imageName);
    for i=1:length(supportedPatterns)
        matchTok = regexpi(fileName, supportedPatterns{i}, 'tokens', 'once');
        if ( isempty(matchTok) )
            continue;
        end
        
        paramPatternSet = '';
        for j=2:length(matchTok)-1
            numDigits = length(matchTok{j})-1;
            paramPattern = ['_' matchTok{j}(1) '%0' num2str(numDigits) 'd'];
            
            paramPatternSet = [paramPatternSet paramPattern];
        end
        
        patternPostfix = [matchTok{end} fileExt];
        
        datasetName = [matchTok{1} '_'];
        namePattern = [matchTok{1} paramPatternSet patternPostfix];
        break;
    end
end
