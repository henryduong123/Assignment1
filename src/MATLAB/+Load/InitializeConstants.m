% InitializeConstants.m - Initialize and add constant values to the global
% CONSTANTS structure.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
%     Copyright 2011 Andrew Cohen, Eric Wait and Mark Winter
%
%     This file is part of LEVer - the tool for stem cell lineaging. See
%     https://pantherfile.uwm.edu/cohena/www/LEVer.html for details
% 
%     LEVer is free software: you can redistribute it and/or modify
%     it under the terms of the GNU General Public License as published by
%     the Free Software Foundation, either version 3 of the License, or
%     (at your option) any later version.
% 
%     LEVer is distributed in the hope that it will be useful,
%     but WITHOUT ANY WARRANTY; without even the implied warranty of
%     MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
%     GNU General Public License for more details.
% 
%     You should have received a copy of the GNU General Public License
%     along with LEVer in file "gnu gpl v3.txt".  If not, see 
%     <http://www.gnu.org/licenses/>.
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function InitializeConstants()
%% Set all constants here

global CONSTANTS

[numChannels numFrames] = Helper.GetImListInfo(CONSTANTS.rootImageFolder, CONSTANTS.imageNamePattern);

Load.AddConstant('numFrames', numFrames,0);
Load.AddConstant('numChannels', numChannels,0);

imSet = Helper.LoadIntensityImageSet(1);

imSizes = zeros(length(imSet),2);
for i=1:length(imSet)
    imSizes(i,:) = size(imSet{i});
end

Load.AddConstant('imageSize', max(imSizes,[],1),0);

if (~isfield(CONSTANTS,'cellType') || isempty(CONSTANTS.cellType))
    cellType = Load.QueryCellType();
    Load.AddConstant('cellType',cellType,1);
end

%% Common Constants
Load.AddConstant('minParentCandidateTimeFrame', 5, 1);
Load.AddConstant('minParentHistoryTimeFrame',   5, 1);
Load.AddConstant('minParentFuture',             5, 1);
Load.AddConstant('minFamilyTimeFrame',          25, 1);
Load.AddConstant('maxFrameDifference',          1, 1);
Load.AddConstant('historySize',                 10, 1);
Load.AddConstant('clickMargin',                 2, 1);
Load.AddConstant('pointClickMargin',            10, 1);
Load.AddConstant('minTrackScore',               0.5,1);
Load.AddConstant('maxPropagateFrames',          50,1);

%% Particular Constants
typeParams = Load.GetCellTypeParameters(CONSTANTS.cellType);
Load.AddConstant('timeResolution', typeParams.leverParams.timeResolution); %in min per frame

Load.AddConstant('maxPixelDistance', typeParams.leverParams.maxPixelDistance, 1);
Load.AddConstant('maxCenterOfMassDistance', typeParams.leverParams.maxCenterOfMassDistance,1);
Load.AddConstant('dMaxConnectComponent', typeParams.leverParams.dMaxConnectComponent,1);

Load.AddConstant('dMaxCenterOfMass', typeParams.trackParams.dMaxCenterOfMass,1);
Load.AddConstant('dMaxConnectComponentTracker', typeParams.trackParams.dMaxConnectComponentTracker,1);

% Try to update channel info based on loaded image data.
channelOrder = typeParams.channelParams.channelOrder;
channelColor = typeParams.channelParams.channelColor;
channelFluor = typeParams.channelParams.channelFluor;
numMissingChan = numChannels - length(channelOrder);
if ( numMissingChan > 0 )
    missingChannels = length(channelOrder):length(channelOrder)+numMissingChan;
    channelOrder = [channelOrder missingChannels];
    channelColor = [channelColor; hsv(numMissingChan+2)];
    channelFluor = [channelFluor false(1,numMissingChan)];
elseif ( numMissingChan < 0 )
    channelOrder = channelOrder(1:numChannels);
    channelColor = channelColor(1:numChannels,:);
    channelFluor = channelFluor(1:numChannels);
end

Load.AddConstant('channelOrder', channelOrder,0);
Load.AddConstant('channelColor', channelColor,0);
Load.AddConstant('channelFluor', channelFluor,0);
end
