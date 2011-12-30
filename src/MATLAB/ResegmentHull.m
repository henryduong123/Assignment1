% ResegmentHull.m - Splits hull into k pieces using kmeans, returns the
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

function [newHulls newFeatures] = ResegmentHull(hull, feature, k, bUserEdit)

global CONSTANTS

newHulls = [];
newFeatures = [];

if ( ~exist('bUserEdit','var') )
    bUserEdit = 0;
end

% k-means clustering of (x,y) coordinates of cell interior
[r c] = ind2sub(CONSTANTS.imageSize, hull.indexPixels);
[kIdx centers] = kmeans([c,r], k, 'Replicates',5, 'EmptyAction','drop');

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

% Calculate new features if passed in feature structure is valids
if ( isempty(feature) )
    return;
end

% [bwDark bwig bwHalo] = SegDarkCenters(hull.time, CONSTANTS.imageAlpha);
center = [hull.centerOfMass(2) hull.centerOfMass(1)];
[bwDark bwig bwHalo] = PartialSegDarkCenters(center, hull.time, CONSTANTS.imageAlpha);

[polyr polyc] = ind2sub(CONSTANTS.imageSize, feature.polyPix);

polydist = Inf*ones(length((polyr)),k);
for i=1:k
    polydist(:,i) = ((polyr-centers(i,2)).^2 + (polyc-centers(i,1)).^2);
end

[dump,polyidx] = min(polydist,[],2);

for i=1:k
    nf = struct('darkRatio',{0}, 'haloRatio',{0}, 'igRatio',{0}, 'darkIntRatio',{0}, 'brightInterior',{0}, 'polyPix',{[]}, 'perimPix',{[]}, 'igPix',{[]}, 'haloPix',{[]});
    if ( feature.brightInterior )
        nf.brightInterior = 1;
    else
        nf.brightInterior = 0;
    end
    polyPix = feature.polyPix(polyidx==i);
    perimPix = BuildPerimPix(polyPix, CONSTANTS.imageSize);
    
    igRat = nnz(bwig(perimPix)) / length(perimPix);
    HaloRat = nnz(bwHalo(perimPix)) / length(perimPix);
    %         bwDarkInterior = bwDarkCenters(polyPix);
    %         DarkRat = nnz(bwDarkInterior) / length(polyPix);
    DarkRat = length(newHulls(i).indexPixels) / length(polyPix);
    
    idxPix = newHulls(i).indexPixels;
    nf.darkRatio = nnz(bwDark(idxPix)) / length(idxPix);
    nf.haloRatio = HaloRat;
    nf.igRatio = igRat;
    nf.darkIntRatio = DarkRat;
    
    
    nf.polyPix = polyPix;
    nf.perimPix = perimPix;
    nf.igPix = find(bwig(perimPix));
    nf.haloPix = find(bwHalo(perimPix));
    
    idxPix = newHulls(i).indexPixels;
    nf.darkRatio = nnz(bwDark(idxPix)) / length(idxPix);
    nf.haloRatio = HaloRat;
    nf.igRatio = igRat;
    nf.darkIntRatio = DarkRat;
    nf.brightInterior = 0;
    
    nf.polyPix = polyPix;
    nf.perimPix = perimPix;
    nf.igPix = find(bwig(perimPix));
    nf.haloPix = find(bwHalo(perimPix));
    
    
    newFeatures = [newFeatures nf];
end


