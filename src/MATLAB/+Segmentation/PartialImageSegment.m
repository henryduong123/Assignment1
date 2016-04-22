% PartialImageSegment.m - Find segmentation results in a small portion of
% an image centered at a clicked point, used to attempt to add missed
% segmentaitons based on user input.

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

function hulls = PartialImageSegment(chanImg, xyCenterPt, subSize, primaryChan, segFunc, segArgs)
    imDims = max(cellfun(@(x)(ndims(x)),chanImg));
    if ( length(subSize) < imDims )
        subSize = repmat(subSize(1), 1,imDims);
    end
    
    imSize = zeros(1,imDims);
    for c=1:length(chanImg)
        imSize = max([imSize; size(chanImg{c})],[],1);
    end
    
    rcCoordMin = floor(Utils.SwapXY_RC(xyCenterPt) - subSize/2);
    rcCoordMax = ceil(Utils.SwapXY_RC(xyCenterPt) + subSize/2);
    
    rcCoordMin(rcCoordMin < 1) = 1;
    rcCoordMax(rcCoordMax > imSize) = imSize(rcCoordMax > imSize);
    
    rcCoordPts = arrayfun(@(x,y)([x:y]),rcCoordMin,rcCoordMax, 'UniformOutput',0);
    
    % Build the subimage to be segmented
    subImSize = zeros(1,imDims);
    chanSubImg = cell(1,length(chanImg));
    for c=1:length(chanImg)
        if ( isempty(chanImg{c}) )
            continue;
        end
        
        chanSubImg{c} = chanImg{c}(rcCoordPts{:});
        subImSize = max([subImSize; size(chanSubImg{c})],[],1);
    end
    
    localHulls = segFunc(chanSubImg, primaryChan, 1, segArgs{:});
    
    hulls = fixupFromSubimage(rcCoordMin, imSize, subImSize, localHulls);
end

function newHulls = fixupFromSubimage(rcCoordMin, origSize, subSize, hulls)
    newHulls = hulls;
    
    rcOffset = rcCoordMin - 1;
    for i=1:length(hulls)
        newHulls(i).indexPixels = makeGlobalPix(hulls(i).indexPixels, origSize, subSize, rcOffset);
    end
end

function globIdx = makeGlobalPix(locIdx, globSz, locSz, rcOffset)
    globCoords = Utils.IndToCoord(locSz, locIdx) + repmat(rcOffset, size(locIdx,1),1);
    globIdx = Utils.CoordToInd(globSz, globCoords);
end
