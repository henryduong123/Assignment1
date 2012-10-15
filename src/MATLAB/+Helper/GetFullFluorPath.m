function pathString = GetFullFluorPath(frame)
global CONSTANTS

fluor = Helper.GetFluorName(frame);

pathString = fullfile(CONSTANTS.rootFluorFolder,fluor);
end

