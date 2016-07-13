% dist = CalcConnectedDistance(startHull,nextHull, rcImageDims, perimMap, cellHulls)
% Calculate the connected-component distance from startHull to nextHull.
% 
% startHull,nextHull - must be valid indices into the cellHulls structure.
%
% rcImageDims - indicates the dimensions (row,column,height) of the image or volume
% the hulls were segmented from (for use in converting cellHulls.indexPixels.
% 
% perimMap = containers.Map('KeyType', 'uint32', 'ValueType', 'any'), must
% be a map handle passed by the calling routine. This shares perimeter
% pixel context between calls in cases where multiple distances will be
% calculated for the same hull set.
% 
% 
% See Tracker.BuildConnectedDistance() for calling examples.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
%     Copyright 2016 Drexel University
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


function dist = CalcConnectedDistance(startHull,nextHull, rcImageDims, perimMap, cellHulls)
    isect = intersect(cellHulls(startHull).indexPixels, cellHulls(nextHull).indexPixels);
    if ( ~isempty(isect) )
        isectDist = 1 - (length(isect) / min(length(cellHulls(startHull).indexPixels), length(cellHulls(nextHull).indexPixels)));
        dist = isectDist;
        return;
    end
    
    addPerim(startHull, rcImageDims,perimMap,cellHulls);
    addPerim(nextHull, rcImageDims,perimMap,cellHulls);
    D = pdist2(perimMap(startHull), perimMap(nextHull));
    
    dist = min(D(:));
end

function addPerim(hullID, rcImageDims, perimMap, cellHulls)
    if ( isKey(perimMap, hullID) )
        return
    end;
    
    pxCell = cell(1,length(rcImageDims));
    [pxCell{:}] = ind2sub(rcImageDims, cellHulls(hullID).indexPixels);
    
    pixelCoords = cell2mat(pxCell);
    minCoord = min(pixelCoords,[],1);
    
    locCoord = pixelCoords - repmat(minCoord, size(pixelCoords,1),1) + 1;
    locMax = max(locCoord,[],1);
    
    if ( any(locMax == 1) )
        perimMap(hullID) = pixelCoords;
        return;
    end
    
    bwIm = false(locMax);
    locCell = mat2cell(locCoord, size(locCoord,1), ones(1,length(rcImageDims)));
    locInd = sub2ind(locMax, locCell{:});
    
    perimCell = cell(1,length(rcImageDims));
    bwIm(locInd) = true;
    perimIm = bwperim(bwIm);
    
    perimIndexes = find(perimIm);
    [perimCell{:}] = ind2sub( size(bwIm), perimIndexes );
    locPerim = cell2mat(perimCell);
    
    perimMap(hullID) = locPerim + repmat(minCoord, size(locPerim,1),1) - 1;
end
