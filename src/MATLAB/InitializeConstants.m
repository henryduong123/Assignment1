function InitializeConstants()
%Set all constants here

%--Eric Wait
global CONSTANTS

CONSTANTS.imageAlpha = 1;
CONSTANTS.maxRetrackDistSq = 40^2;
CONSTANTS.maxPixelDistance = 40;
CONSTANTS.maxCenterOfMassDistance = 80;
CONSTANTS.minParentCandidateTimeFrame = 5;
CONSTANTS.minParentHistoryTimeFrame = 5;
CONSTANTS.minParentFuture = 5;
CONSTANTS.minFamilyTimeFrame = 5;
CONSTANTS.maxFrameDifference = 5;
CONSTANTS.historySize = 50;
CONSTANTS.clickMargin = 500;
CONSTANTS.timeResolution = 10; %in frames per min
CONSTANTS.dMaxConnectComponet = 40;
CONSTANTS.dMaxCenterOfMass = 80;
CONSTANTS.lookAhead = 2;
CONSTANTS.minPlayer = 9;
CONSTANTS.minMitosis = 30;
end