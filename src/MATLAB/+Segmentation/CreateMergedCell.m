% CreateMergedCell.m - Given a list of cells create a single merged cell.

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

function [mergeObj, deleteCells] = CreateMergedCell(mergeCells)
    global CONSTANTS CellHulls
    
    mergeObj = [];
    deleteCells = [];
    
    szC = length(mergeCells);
    largestC = 1;
    C = ones(1,length(mergeCells));
    
    if ( szC > 1 )
        deleteCells = mergeCells(C == largestC);
        
        mergeObj.time = CellHulls(deleteCells(1)).time;
        mergeObj.indexPixels = vertcat(CellHulls(deleteCells).indexPixels);
        mergeObj.imagePixels = vertcat(CellHulls(deleteCells).imagePixels);
        
        [r c] = ind2sub(CONSTANTS.imageSize, mergeObj.indexPixels);
        try
            ch = convhull(r,c);
        catch err
        end
        
        mergeObj.points = [c(ch) r(ch)];
        mergeObj.centerOfMass = mean([r c]);
        mergeObj.deleted = false;
        mergeObj.userEdited = false;
    end
end

function ccM = calcConnDistM(cells)
    global CONSTANTS CellHulls
    
    ccM = zeros(length(cells), length(cells));
    for i=1:length(cells)
        for j=1:length(cells)
            if ( i == j )
                ccM(i,j) = Inf;
                continue;
            end
            
            [ri ci] = ind2sub(CONSTANTS.imageSize, CellHulls(cells(i)).indexPixels);
            [rj cj] = ind2sub(CONSTANTS.imageSize, CellHulls(cells(j)).indexPixels);
            
            [idxi, idxj] = ndgrid(1:length(ri), 1:length(rj));
            
            distsq = ((ri(idxi)-rj(idxj)).^2 + (ci(idxi)-cj(idxj)).^2);
            ccM(i,j) = sqrt(min(distsq(:)));
        end
    end
end

