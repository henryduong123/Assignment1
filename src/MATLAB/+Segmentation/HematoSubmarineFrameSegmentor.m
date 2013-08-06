function [objs features] = HematoSubmarineFrameSegmentor(im, t)
    global CONSTANTS
    
    objs = [];
    features = [];
    % hemato submarines
    if strcmp(CONSTANTS.cellType, 'Hemato')
        [sharpImg blurImg bw] = michelContrastEnhance(1-im);
%        [bw] = Segmentation.Michel(1-im, [3 3]);
        
        [centers, radii, metric] = imfindcircles(bw, [10 20], 'Sensitivity', 0.9);
        [r c] = find(bw >= 0);
        for i=1:length(radii)
            % find the pixels inside the circle
            dist = ((c - centers(i,1)).^2 + (r - centers(i,2)).^2);
            pix = find(dist <= radii(i)^2);
            [r1 c1] = ind2sub(size(im), pix);
            
            % find the convex hull of the circle
            ch = convhull(c1, r1);
            
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
end

function [sharpImg blurImg bw] = michelContrastEnhance(img)

    bluriter = 20;
    blurradius = 15;
    blurstd = 5;

    smoothFilt = fspecial('gaussian', 2*blurradius*(bluriter)+1, sqrt(bluriter)*blurstd);

    blurImg = imfilter(img, smoothFilt, 'symmetric');
    sharpImg = max(0, img - blurImg);

    % median filter the high-frequency image
    medim = medfilt2(sharpImg,[5 5]);

    % The rest of this code removes purely zero values then uses an otsu threshold to segment the image
    medimZ = medim(medim>0);

    th = graythresh(medimZ);
    bw = im2bw(medim,th);
end
