% ResegmentHull.m - Splits hull into k pieces using a gaussian mixture model,
% returns the k split hulls or [] if there are errors.

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

function [newHulls newFeatures] = ResegmentHull(hull, feature, k, bUserEdit, bKmeansInit)

global CONSTANTS

newHulls = [];
newFeatures = [];

if ( ~exist('bUserEdit','var') )
    bUserEdit = 0;
end

% guassian clustering (x,y) coordinates of cell interior
[r c] = ind2sub(CONSTANTS.imageSize, hull.indexPixels);
gmoptions = statset('Display','off', 'MaxIter',200);

if(exist('bKmeansInit', 'var') && bKmeansInit)
    %initialize GMM using kmeans result instead of randomly
    % ~10x faster but ocassionally poor results - used for interactivity
    [kIdx centers] = kmeans([c,r], k, 'Replicates',5, 'EmptyAction','drop');
    start = struct('mu', {centers}, 'Sigma', {repmat(eye(2,2), [1 1 k])},'PComponents',{(ones(1,k)/k)});
    obj = gmdistribution.fit([c,r], k, 'Start', start, 'Options',gmoptions);
else
    obj = gmdistribution.fit([c,r], k, 'Replicates',15, 'Options',gmoptions);
end

kIdx = cluster(obj, [c,r]);

if ( any(isnan(kIdx)) )
    return;
end

connComps = cell(1,k);

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
    
    connComps{i} = hull.indexPixels(bIdxPix);
    
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

% Define an ordering on the hulls selected, COM is unique per component so
% this gives a deterministic ordering to the components
[sortCOM, sortIdx] = sortrows(vertcat(newHulls.centerOfMass));
newHulls = newHulls(sortIdx);
connComps = connComps(sortIdx);

% Calculate new features if passed in feature structure is valids
if ( isempty(feature) )
    return;
end

% [bwDark bwig bwHalo] = SegDarkCenters(hull.time, CONSTANTS.imageAlpha);
center = [hull.centerOfMass(2) hull.centerOfMass(1)];
[bwDark bwig bwHalo] = Segmentation.PartialSegDarkCenters(center, hull.time, CONSTANTS.imageAlpha);

polyidx = Segmentation.AssignPolyPix(feature.polyPix, connComps, CONSTANTS.imageSize);

% [polyr polyc] = ind2sub(CONSTANTS.imageSize, feature.polyPix);
% 
% polydist = Inf*ones(length((polyr)),k);
% for i=1:k
%     polydist(:,i) = ((polyr-centers(i,2)).^2 + (polyc-centers(i,1)).^2);
% end
% 
% [dump,polyidx] = min(polydist,[],2);

% % Debug test draw code
% fileName = [CONSTANTS.rootImageFolder CONSTANTS.datasetName '_t' Helper.GetDigitString(hull.time) '.TIF'];
% if exist(fileName,'file')
%     im = Helper.LoadIntensityImage(fileName);
% else
%     im=zeros(CONSTANTS.imageSize);
% end
% cmap = hsv(2*k);
% figure;imagesc(im);colormap(gray);hold on;
% for i=1:k
%     [tstr tstc] = ind2sub(CONSTANTS.imageSize, newHulls(i).indexPixels);
%     plot(tstc,tstr, '.', 'Color',cmap(i,:));
%     [tstr tstc] = ind2sub(CONSTANTS.imageSize, feature.polyPix(polyidx==i));
%     plot(tstc,tstr, 'o', 'Color',cmap(2+i,:));
% end

for i=1:k
    nf = struct('darkRatio',{0}, 'haloRatio',{0}, 'igRatio',{0}, 'darkIntRatio',{0}, 'brightInterior',{0}, 'polyPix',{[]}, 'perimPix',{[]}, 'igPix',{[]}, 'haloPix',{[]});
    if ( feature.brightInterior )
        nf.brightInterior = 1;
    else
        nf.brightInterior = 0;
    end
    polyPix = feature.polyPix(polyidx==i);
    perimPix = Segmentation.BuildPerimPix(polyPix, CONSTANTS.imageSize);
    
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


