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

function newHulls  = ResegmentHull(hull, k, bUserEdit, bKmeansInit)

global CONSTANTS CellHulls

newHulls = [];

if ( ~exist('bUserEdit','var') )
    bUserEdit = 0;
end

if (~exist('bKmeansInit', 'var'))
    bKmeansInit = 0;
end

% guassian clustering (x,y) coordinates of cell interior
[r c] = ind2sub(CONSTANTS.imageSize, hull.indexPixels);
gmoptions = statset('Display','off', 'MaxIter',400);



switch CONSTANTS.cellType
    case 'Adult'
        if(bKmeansInit)
            %initialize GMM using kmeans result instead of randomly
            % ~10x faster but ocassionally poor results - used for interactivity
            [kIdx centers] = kmeans([c,r], k, 'Replicates',5, 'EmptyAction','drop');
            start = struct('mu', {centers}, 'Sigma', {repmat(eye(2,2), [1 1 k])},'PComponents',{(ones(1,k)/k)});
            obj = Helper.fitGMM([c,r], k, 'Start',start, 'Options',gmoptions);
        else
            obj = Helper.fitGMM([c,r], k, 'Replicates',15, 'Options',gmoptions);
        end
        kIdx = cluster(obj, [c,r]);
    case 'Embryonic'
        obj = Helper.fitGMM([c,r], k, 'Replicates',15, 'Options',gmoptions);
        kIdx = cluster(obj, [c,r]);
    otherwise
        [kIdx centers] = kmeans([c,r], k, 'Replicates',5, 'EmptyAction','drop');
end

if ( any(isnan(kIdx)) )
    return;
end

connComps = cell(1,k);

nh = Helper.MakeEmptyStruct(CellHulls);
nh.userEdited = forceLogical(bUserEdit);
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
    nh.centerOfMass = mean([hy hx]);
    nh.time = hull.time;
    
    chIdx = Helper.ConvexHull(hx,hy);
    if ( isempty(chIdx) )
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
end

function bValue = forceLogical(value)
    bValue = (value ~= 0);
end

