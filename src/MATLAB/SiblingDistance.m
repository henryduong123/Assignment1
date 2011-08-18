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

function distance = SiblingDistance(cell1HullID,cell2HullID)
%This will give you a weighted cost dependent on the distance between two
%cell hulls.  It uses the CONSTANTS: imageSize, maxCenterOfMassDistance,
%and maxPixelDistance.  Make sure they are set in the global CONSTANTS
%variable.


global CellHulls CONSTANTS

if 0 == cell1HullID || 0 == cell2HullID
    distance = Inf;
    return;
end

if CellHulls(cell1HullID).time ~= CellHulls(cell2HullID).time
    distance = Inf;
    return
end

pixelsCell1 = CellHulls(cell1HullID).indexPixels;
pixelsCell2 = CellHulls(cell2HullID).indexPixels;

if (length(pixelsCell2) < length(pixelsCell1))
    temp = pixelsCell2;
    pixelsCell1 = pixelsCell2;
    pixelsCell2 = temp;
end

[yCell1 xCell1] = ind2sub(CONSTANTS.imageSize,pixelsCell1);
[yCell2 xCell2] = ind2sub(CONSTANTS.imageSize,pixelsCell2);

minPixelDistance = Inf;

for i=1:length(yCell1)
    distanceSqr = (yCell2 - yCell1(i)).^2 + (xCell2-xCell1(i)).^2;
    curMinDistance = sqrt(min(distanceSqr));
    if(curMinDistance < minPixelDistance)
        minPixelDistance = curMinDistance;
    end
end

distanceCenterOfMass = norm(CellHulls(cell1HullID).centerOfMass - CellHulls(cell2HullID).centerOfMass);

distance = distanceCenterOfMass + 1000 * minPixelDistance;

if(distanceCenterOfMass > CONSTANTS.maxCenterOfMassDistance ||...
        minPixelDistance > CONSTANTS.maxPixelDistance)
    distance = inf;
end
end
