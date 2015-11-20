function SetImageInfo()
    global CONSTANTS
    [channelList, frameList] = Helper.GetImListInfo(CONSTANTS.rootImageFolder, CONSTANTS.imageNamePattern);

    Load.AddConstant('numFrames', frameList(end),0);
    Load.AddConstant('numChannels', channelList(end),0);

    imSet = Helper.LoadIntensityImageSet(1);

    imSizes = zeros(length(imSet),2);
    for i=1:length(imSet)
        imSizes(i,:) = size(imSet{i});
    end

    Load.AddConstant('imageSize', max(imSizes,[],1),0);
end