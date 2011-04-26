function InitializeConstants()
%Set all constants here

%--Eric Wait

AddConstant('imageAlpha',1.5);
AddConstant('maxRetrackDistSq',40^2);
AddConstant('maxPixelDistance',40);
AddConstant('maxCenterOfMassDistance',80);
AddConstant('minParentCandidateTimeFrame',5);
AddConstant('minParentHistoryTimeFrame',5);
AddConstant('minParentFuture',1);
AddConstant('minFamilyTimeFrame',5);
AddConstant('maxFrameDifference',1);
AddConstant('historySize',50);
AddConstant('clickMargin',500);
AddConstant('timeResolution',10); %in frames per min
AddConstant('dMaxConnectComponet',40);
AddConstant('dMaxCenterOfMass',80);
end