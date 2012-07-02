function imageName = GetImageName(frame)
global CONSTANTS

imageName = sprintf(CONSTANTS.imageNamePattern,frame);
end

