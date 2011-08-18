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

% Gets original (partial) segmentation from cells which were split and a
% list of the split cells which intersect the original segmentation
% component.
function [newObj mergeHulls] = FindMergedCell(t, centerPt)
    global CONSTANTS CellHulls HashedCells

    fileName = [CONSTANTS.rootImageFolder CONSTANTS.datasetName '_t' SignificantDigits(t) '.TIF'];
    [img colorMap] = imread(fileName);
    img = mat2gray(img);
    
    mergeHulls = [];
    newObj = PartialImageSegment(img, centerPt, 200, CONSTANTS.imageAlpha);
    
    if ( isempty(newObj) )
        return;
    end
    
    chkHulls = [HashedCells{t}.hullID];
    
    bMergeHull = false(length(chkHulls));
    for i=1:length(chkHulls)
        bMergeHull(i) = any(ismember(newObj.indexPixels,CellHulls(chkHulls(i)).indexPixels));
    end
    
    mergeHulls = chkHulls(bMergeHull);
end