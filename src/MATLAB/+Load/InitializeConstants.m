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
%Set all constants here

Load.AddConstant('imageAlpha',1.5);
Load.AddConstant('maxPixelDistance',40,1);
Load.AddConstant('maxCenterOfMassDistance',40,1);
Load.AddConstant('minParentCandidateTimeFrame',5, 1);
Load.AddConstant('minParentHistoryTimeFrame',5, 1);
Load.AddConstant('minParentFuture',5, 1);
Load.AddConstant('minFamilyTimeFrame',25, 1);
Load.AddConstant('maxFrameDifference',1, 1);
Load.AddConstant('historySize',10, 1);
Load.AddConstant('clickMargin',500, 1);
Load.AddConstant('timeResolution',10); %in frames per min
Load.AddConstant('dMaxConnectComponent',40,1);
Load.AddConstant('dMaxCenterOfMass',40,1);
Load.AddConstant('minTrackScore',0.5,1);
Load.AddConstant('maxPropagateFrames',50,1);
end
