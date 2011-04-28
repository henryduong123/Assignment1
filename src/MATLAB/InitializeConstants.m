function InitializeConstants()
%Set all constants here

%--Eric Wait

AddConstant('imageAlpha',1.5);
AddConstant('maxPixelDistance',40);
AddConstant('maxCenterOfMassDistance',80);
AddConstant('minParentCandidateTimeFrame',5, 1);
AddConstant('minParentHistoryTimeFrame',5, 1);
AddConstant('minParentFuture',5, 1);
AddConstant('minFamilyTimeFrame',5, 1);
AddConstant('maxFrameDifference',1, 1);
AddConstant('historySize',50, 1);
AddConstant('clickMargin',500, 1);
AddConstant('timeResolution',10); %in frames per min
AddConstant('dMaxConnectComponet',40);
AddConstant('dMaxCenterOfMass',80);
end