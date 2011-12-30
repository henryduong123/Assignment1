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

function [mergeObj, mergeFeat, deleteCells] = CreateMergedCell(mergeCells)
    global CONSTANTS CellHulls CellFeatures
    
    mergeObj = [];
    mergeFeat = [];
    deleteCells = [];
    
    ccM = calcConnDistM(mergeCells);
    [S,C] = graphconncomp(sparse(ccM <= 5));
    
    largestC = 0;
    szC = 0;
    for i=1:S
        if ( nnz(C==i) > szC )
            largestC = i;
            szC = nnz(C==i);
        end
    end
    
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
        
        % Calculate merged cell features
        if ( isempty(CellFeatures) )
            return;
        end
        
        mergeFeat = struct('darkRatio',{0}, 'haloRatio',{0}, 'igRatio',{0}, 'darkIntRatio',{0}, 'brightInterior',{0}, 'polyPix',{[]}, 'perimPix',{[]}, 'igPix',{[]}, 'haloPix',{[]});
        
%         [bwDark bwig bwHalo] = SegDarkCenters(mergeObj.time, CONSTANTS.imageAlpha);
        center = [mergeObj.centerOfMass(2) mergeObj.centerOfMass(1)];
        [bwDark bwig bwHalo] = PartialSegDarkCenters(center, mergeObj.time, CONSTANTS.imageAlpha);
        
        allPolyPix = vertcat(CellFeatures(deleteCells).polyPix);
        [polyr polyc] = ind2sub(CONSTANTS.imageSize, allPolyPix);
        
        xlims = Clamp([min(polyc)-5 max(polyc)+5], 1, CONSTANTS.imageSize(2));
        ylims = Clamp([min(polyr)-5 max(polyr)+5], 1, CONSTANTS.imageSize(1));
        
        locr = polyr - ylims(1) + 1;
        locc = polyc - xlims(1) + 1;
        
        locsz = [ylims(2)-ylims(1) xlims(2)-xlims(1)]+1;
        locind = sub2ind(locsz, locr, locc);

        locbwpoly = false(locsz);
        locbwpoly(locind) = 1;
        
%         figure;imagesc(locbwpoly);colormap(gray);hold on;
        
        % Do a bit of smoothing and attempt to get all "polys" on same
        % connected component
        for i=1:4
            se = strel('disk',i);
            connpoly = imclose(locbwpoly,se);
            [LConn,NConn] = bwlabel(connpoly);
            if ( NConn == 1 )
                break;
            end
        end
        
        [nr nc] = find(connpoly);
%         plot(nc,nr,'.r');
        
        polyr = nr + ylims(1) - 1;
        polyc = nc + xlims(1) - 1;
        
        polyPix = sub2ind(CONSTANTS.imageSize, polyr, polyc);
        perimPix = BuildPerimPix(polyPix, CONSTANTS.imageSize);
        
        igRat = nnz(bwig(perimPix)) / length(perimPix);
        HaloRat = nnz(bwHalo(perimPix)) / length(perimPix);
        
%         bwDarkInterior = bwDarkCenters(polyPix);
%         DarkRat = nnz(bwDarkInterior) / length(polyPix);
        DarkRat = length(mergeObj.indexPixels) / length(polyPix);

        %
        idxPix = mergeObj.indexPixels;
        mergeFeat.darkRatio = nnz(bwDark(idxPix)) / length(idxPix);
        mergeFeat.haloRatio = HaloRat;
        mergeFeat.igRatio = igRat;
        mergeFeat.darkIntRatio = DarkRat;
        mergeFeat.brightInterior = 0;

        mergeFeat.polyPix = polyPix;
        mergeFeat.perimPix = perimPix;
        mergeFeat.igPix = find(bwig(perimPix));
        mergeFeat.haloPix = find(bwHalo(perimPix));
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