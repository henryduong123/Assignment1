
%TODO: Maybe handle convex hull intersection instead of interior points as
%the current method still allows considerable hull overlap in some cases.

function newObj = ForceDisjointSeg(obj, time, centerPt)
    global CONSTANTS CellHulls HashedCells
    
    newObj = [];
    
    ccidxs = vertcat(CellHulls([HashedCells{time}.hullID]).indexPixels);
    pix = obj.indPixels;
    
    bPickPix = ~ismember(pix, ccidxs);
    
    if ( all(bPickPix) )
        newObj = obj;
        return;
    end
    
    bwimg = zeros(CONSTANTS.imageSize);
    bwimg(pix(bPickPix)) = 1;
    
    CC = bwconncomp(bwimg,8);
    if ( CC.NumObjects < 1 )
        newObj = [];
        return;
    end
    
    for i=1:CC.NumObjects
        [r c]=ind2sub(size(bwimg),CC.PixelIdxList{i});
        try
            ch = convhull(r,c);
        catch errmsg
            continue;
        end
        
        if ( inpolygon(centerPt(1), centerPt(2), c(ch), r(ch)) )
            bCCPix = ismember(pix, CC.PixelIdxList{i});
            
            newObj.indPixels = CC.PixelIdxList{i};
            newObj.imPixels = obj.imPixels(bCCPix);
            
            newObj.points = [c(ch) r(ch)];
%             newobj.COM = mean([r c]);
            
            break;
        end
    end
end