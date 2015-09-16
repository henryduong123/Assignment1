function pathString = GetFullImagePath(chan, frame)
global CONSTANTS

imageName = Helper.GetImageName(chan, frame);

pathString = fullfile(CONSTANTS.rootImageFolder,imageName);
end

