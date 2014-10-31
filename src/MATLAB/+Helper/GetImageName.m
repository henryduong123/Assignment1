function imageName = GetImageName(chan, frame)
global CONSTANTS

imageName = sprintf(CONSTANTS.imageNamePattern, chan,frame);
end

