% hullID = FindHull(curPoint) 
% This function will find the closest hull to the given point
% and return the hullID if it is within CONSTANTS.clickMargin

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

function hullID = FindHull(time, curPoint)
    global CONSTANTS CellHulls HashedCells

    hullID = -1;
    
    chkPoint = curPoint(1,1:2);
    
    frameHulls = [HashedCells{time}.hullID];
    bMayOverlap = Hulls.RadiusContains(frameHulls, CONSTANTS.pointClickMargin, chkPoint);

    chkHulls = frameHulls(bMayOverlap);

    bInHull = false(1,length(chkHulls));
    for i=1:length(chkHulls)
        if ( size(CellHulls(chkHulls(i)).points,1) == 1 )
            bInHull(i) = Hulls.ExpandedHullContains(CellHulls(chkHulls(i)).points, CONSTANTS.pointClickMargin, chkPoint);
        else
            bInHull(i) = Hulls.ExpandedHullContains(CellHulls(chkHulls(i)).points, CONSTANTS.clickMargin, chkPoint);
        end
    end
    
    if ( nnz(bInHull) == 0 )
        return;
    end
    
    if ( nnz(bInHull) > 1 )
        chkHulls = chkHulls(bInHull);
        distSq = getHullDistanceSq(chkHulls, chkPoint);
        [minDist minIdx] = min(abs(distSq));
        
        hullID = chkHulls(minIdx);
        return;
    end
    
    hullID = chkHulls(bInHull);
end

function hullDistSq = getHullDistanceSq(hullIDs, point)
    global CellHulls
    
    hullDistSq = zeros(1,length(hullIDs));
    for i=1:length(hullIDs)
        hullDistSq(i) = hullProjDist(CellHulls(hullIDs(i)).points, point);
    end
end

function hullDistSq = hullProjDist(segPts, point)
    numSeg = size(segPts,1);
    
    if ( isempty(segPts) )
        error('Empty segmentation unsupported');
    end
    
    if ( numSeg == 1 )
        hullDistSq = sum((point - segPts).^2, 2);
        return;
    end
    
    numSeg = numSeg-1;

    planes = segPts(2:end,:) - segPts(1:(end-1),:);
    planeLen = sqrt(sum(planes.^2, 2));
    planes = planes ./ repmat(planeLen, 1, 2);
    normPlanes = [-planes(:,2) planes(:,1)];
    
    if ( det([planes(1,:); planes(2,:)]) > 0 )
        normPlanes = -normPlanes;
    end
    
    locVec = repmat(point,numSeg,1) - segPts(1:(end-1),:);
    
    locX = sum(planes.*locVec, 2);
    locY = sum(normPlanes.*locVec, 2);
    
    sgnMul = sign(locY);
    bLeft = (locX < 0);
    bRight = (locX > planeLen);
    bMid = ~(bLeft | bRight);
    
    segDist = zeros(numSeg,1);
    segDist(bLeft) = (locX(bLeft).^2 + locY(bLeft).^2);
    segDist(bRight) = ((locX(bRight)-planeLen(bRight)).^2 + locY(bRight).^2);
    segDist(bMid) = (locY(bMid).^2);
    
    [hullDistSq minIdx] = min(segDist,[],1);
    hullDistSq = sign(locY(minIdx)) * hullDistSq;
end
