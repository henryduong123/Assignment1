% We've already segmented the fluor images, so all we need to do here is
% find the convex hulls in the image that's passed in.
function [objs features] = FluorHulls(im, t)
    objs = [];
    features = [];
    
    [L num] = bwlabel(im);
    for n=1:num
        [r c] = find(L==n);
        pix = find(L == n);
        
        ch = convhull(c, r);
        no = [];
        no.t = t;
        no.points = [c(ch), r(ch)];
        no.ID = -1;
        no.indPixels = pix;
        no.indTailPixels  = [];
        no.BrightInterior=1;
        no.Eccentricity=0;
        no.imPixels=im(pix);
        
        nf = [];
        nf.darkRatio = 0;
        nf.haloRatio = 0;
        nf.igRatio = 0;
        nf.darkIntRatio = 0;
        nf.brightInterior = 1;
        
        nf.polyPix = [];
        nf.perimPix = [];
        nf.igPix = [];
        nf.haloPix = [];
        
        objs=[objs no];
        features = [features nf];
    end
end
