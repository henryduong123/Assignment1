% SiblingDistance.m - 
% This will give a weighted cost dependent on the distance between two
% cell hulls.  It uses the CONSTANTS: imageSize, maxCenterOfMassDistance,
% and maxPixelDistance.  Make sure they are set in the global CONSTANTS
% variable.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
%     Copyright 2011-2016 Andrew Cohen
%
%     This file is part of LEVer - the tool for stem cell lineaging. See
%     http://n2t.net/ark:/87918/d9rp4t for details
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

function distance = SiblingDistance(cell1HullID,cell2HullID)

global CellHulls CONSTANTS

distance = Inf;

if 0 == cell1HullID || 0 == cell2HullID
    return;
end

if CellHulls(cell1HullID).time ~= CellHulls(cell2HullID).time
    return
end

hullPerims = containers.Map('KeyType','uint32', 'ValueType','any');

ccDist = Helper.CalcConnectedDistance(cell1HullID,cell2HullID, Metadata.GetDimensions('rc'), hullPerims, CellHulls);
distanceCenterOfMass = norm(CellHulls(cell1HullID).centerOfMass - CellHulls(cell2HullID).centerOfMass);

if(distanceCenterOfMass > CONSTANTS.maxCenterOfMassDistance || ccDist > CONSTANTS.maxPixelDistance)
    return;
end

distance = distanceCenterOfMass + 1000 * ccDist;
end
