function pathString = GetFullImagePath(frame)
global CONSTANTS

image = Helper.GetImageName(frame);

pathString = fullfile(CONSTANTS.rootImageFolder,image);
end

