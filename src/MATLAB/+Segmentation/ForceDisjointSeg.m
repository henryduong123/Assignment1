
%TODO: Maybe handle convex hull intersection instead of interior points as
%the current method still allows considerable hull overlap in some cases.

function newHull = ForceDisjointSeg(hull, time, centerPt)
    global CONSTANTS CellHulls HashedCells
    
    newHull = [];
    
    ccidxs = vertcat(CellHulls([HashedCells{time}.hullID]).indexPixels);
    pix = hull.indexPixels;
    
    bPickPix = ~ismember(pix, ccidxs);
    
    if ( all(bPickPix) )
        newHull = hull;
        return;
    end
    
    bwimg = zeros(CONSTANTS.imageSize);
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
            
            newHull.indexPixels = CC.PixelIdxList{i};
            newHull.points = [c(ch) r(ch)];
            break;
        end
    end
end
