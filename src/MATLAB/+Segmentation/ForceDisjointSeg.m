
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
%     Copyright 2011-2016 Andrew Cohen
%
%     This file is part of LEVer - the tool for stem cell lineaging. See
%     http://n2t.net/ark:/87918/d9rp4t for details
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


%TODO: Maybe handle convex hull intersection instead of interior points as
%the current method still allows considerable hull overlap in some cases.

function newHull = ForceDisjointSeg(hull, time, centerPt)
    global CellHulls HashedCells
    
    newHull = [];
    
    ccidxs = vertcat(CellHulls([HashedCells{time}.hullID]).indexPixels);
    pix = hull.indexPixels;
    
    bPickPix = ~ismember(pix, ccidxs);
    
    if ( all(bPickPix) )
        newHull = hull;
        return;
    end
    
    bwimg = zeros(Metadata.GetDimensions('rc'));
    bwimg(pix(bPickPix)) = 1;
    
    CC = bwconncomp(bwimg,8);
    if ( CC.NumObjects < 1 )
        newHull = [];
        return;
    end
    
    for i=1:CC.NumObjects
        [r c]=ind2sub(size(bwimg),CC.PixelIdxList{i});
        ch = Helper.ConvexHull(c,r);
        if ( isempty(ch) )
            continue;
        end
        
        if ( inpolygon(centerPt(1), centerPt(2), c(ch), r(ch)) )
            bCCPix = ismember(pix, CC.PixelIdxList{i});
            
            newHull = hull;
            
            newHull.indexPixels = CC.PixelIdxList{i};
            newHull.points = [c(ch) r(ch)];
            break;
        end
    end
end
