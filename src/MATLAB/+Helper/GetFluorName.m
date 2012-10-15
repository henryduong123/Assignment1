function fluorName = GetFluorName(frame)
global CONSTANTS

fluorName = sprintf(CONSTANTS.fluorNamePattern,frame);
end

