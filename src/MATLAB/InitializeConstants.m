%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
%     This file is part of LEVer.exe
%     (C) 2011 Andrew Cohen, Eric Wait and Mark Winter
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function InitializeConstants()
%Set all constants here


AddConstant('imageAlpha',1.5);
AddConstant('maxPixelDistance',40,1);
AddConstant('maxCenterOfMassDistance',40,1);
AddConstant('minParentCandidateTimeFrame',5, 1);
AddConstant('minParentHistoryTimeFrame',5, 1);
AddConstant('minParentFuture',5, 1);
AddConstant('minFamilyTimeFrame',5, 1);
AddConstant('maxFrameDifference',1, 1);
AddConstant('historySize',50, 1);
AddConstant('clickMargin',500, 1);
AddConstant('timeResolution',10); %in frames per min
AddConstant('dMaxConnectComponent',40,1);
AddConstant('dMaxCenterOfMass',40,1);
end