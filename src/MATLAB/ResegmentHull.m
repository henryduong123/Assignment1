%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
%     This file is part of LEVer.exe
%     (C) 2011 Andrew Cohen, Eric Wait and Mark Winter
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function newHulls = ResegmentHull(hull, k)
% Splits hull int k pieces using kmeans, returns the k split hulls or [] if
% there are errors.


global CONSTANTS

newHulls = [];

% k-means clustering of (x,y) coordinates of cell interior
[r c] = ind2sub(CONSTANTS.imageSize, hull.indexPixels);
kIdx = kmeans([c,r], k, 'Replicates',5, 'EmptyAction','drop');

if ( any(isnan(kIdx)) )
    return;
end

nh = struct('time', [], 'points', [], 'centerOfMass', [], 'indexPixels', [], 'imagePixels', [], 'deleted', 0);
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
