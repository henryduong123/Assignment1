% ResegmentHull.m - Splits hull int k pieces using kmeans, returns the 
% k split hulls or [] if there are errors.

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

function newHulls = ResegmentHull(hull, k, bUserEdit)

global CONSTANTS

newHulls = [];

if ( ~exist('bUserEdit','var') )
    bUserEdit = 0;
end

% k-means clustering of (x,y) coordinates of cell interior
[r c] = ind2sub(CONSTANTS.imageSize, hull.indexPixels);
kIdx = kmeans([c,r], k, 'Replicates',5, 'EmptyAction','drop');

if ( any(isnan(kIdx)) )
    return;
end

nh = struct('time', [], 'points', [], 'centerOfMass', [], 'indexPixels', [], 'imagePixels', [], 'deleted', 0, 'userEdited', bUserEdit);
for i=1:k
    bIdxPix = (kIdx == i);
    
    hx = c(bIdxPix);
    hy = r(bIdxPix);
    
    % If any sub-object is less than 15 pixels then cannot split this
    % hull
    if ( nnz(bIdxPix) < 15 )
        newHulls = [];
        return;
    end
    
    nh.indexPixels = hull.indexPixels(bIdxPix);
    nh.imagePixels = hull.imagePixels(bIdxPix);
    nh.centerOfMass = mean([hy hx]);
    nh.time = hull.time;
    
    try
        chIdx = convhull(hx, hy);
    catch excp
        newHulls = [];
        return;
    end
    
    nh.points = [hx(chIdx) hy(chIdx)];
    
    newHulls = [newHulls nh];
end
end
