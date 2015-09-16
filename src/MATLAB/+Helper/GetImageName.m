function imageName = GetImageName(chan, frame)
global CONSTANTS

valueNames = {'c' 't'};
paramValues = {chan frame};

paramTokens = Helper.GetNamePatternParams(CONSTANTS.imageNamePattern);
paramOrder = cellfun(@(x)(x{1}),paramTokens, 'UniformOutput',0);

[bHasParam,valueIdx] = ismember(paramOrder, valueNames);
if ( ~all(bHasParam) )
    imageName = '';
    
    missingValues = cellfun(@(x)([' ' x]), paramOrder(bHasParam));
    fprintf('Unspecified value(s) needed to generate image string:%s\n', missingValues);
    return;
end

imageName = sprintf(CONSTANTS.imageNamePattern, paramValues{valueIdx});
end

