function distance = SiblingDistance(cell1HullID,cell2HullID)
%This will give you a weighted cost dependent on the distance between two
%cell hulls.  It uses the CONSTANTS: imageSize, maxCenterOfMassDistance,
%and maxPixelDistance.  Make sure they are set in the global CONSTANTS
%variable.

%--Eric Wait

global CellHulls CONSTANTS

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
