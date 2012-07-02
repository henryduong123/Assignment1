function pathString = GetFullImagePath(frame)
global CONSTANTS

image = Helper.GetImageName(frame);

pathString = [CONSTANTS.rootImageFolder image];
end

