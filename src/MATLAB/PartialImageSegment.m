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

function [hull feature] = PartialImageSegment(img, centerPt, subSize, alpha)
    
    if ( length(subSize) < 2 )
        subSize = [subSize(1) subSize(1)];
    end
    
    imSize = size(img);
    
    coordMin = floor([centerPt(1)-subSize(1)/2 centerPt(2)-subSize(2)/2]);
    coordMin(coordMin < 1) = 1;
    
    coordMax = ceil([centerPt(1)+subSize(1)/2 centerPt(2)+subSize(2)/2]);
    if ( coordMax(1) > imSize(2) )
        coordMax(1) = imSize(2);
    end
    if ( coordMax(2) > imSize(1) )
        coordMax(2) = imSize(1);
    end
    
    % Build the subimage to be segmented
    subImg = img(coordMin(2):coordMax(2), coordMin(1):coordMax(1));
    
    [objs features] = FrameSegmentor(subImg, 1, alpha);
    
    bInHull = CHullContainsPoint(centerPt, objs);
    
    hull = objs(find(bInHull,1));
    feature = features(find(bInHull,1));
end

