function [bwDark bwig bwHalo xlims ylims] = PartialSegDarkCenters(centerPt, t, imageAlpha)
    global CONSTANTS SegLevels
    
    fileName = [CONSTANTS.rootImageFolder CONSTANTS.datasetName '_t' SignificantDigits(t) '.TIF'];
    if exist(fileName,'file')
        [img colrMap] = imread(fileName);
    else
        img=zeros(CONSTANTS.imageSize);
    end
    im = mat2gray(img);
    
    smsz = 150;
    
    xlims = Clamp(round([centerPt(1)-smsz centerPt(1)+smsz]),1,size(im,2));
    ylims = Clamp(round([centerPt(2)-smsz centerPt(2)+smsz]),1,size(im,1));
    
    locIm = im(ylims(1):ylims(2),xlims(1):xlims(2));
    
    % rerun part of seg
    level = imageAlpha*SegLevels(t).haloLevel;
    locbwHalo = im2bw(locIm,level);

    locbwDark = false(size(locIm));
    seBig = strel('square',19);

    se = strel('square',3);
    gd = imdilate(locIm,se);
    ge = imerode(locIm,se);
    ig = gd - ge;
    lig = SegLevels(t).igLevel;
    locbwig = im2bw(ig,lig);

    bwmask = imclose(locbwig,seBig);
    % find dark chewy centers
    CC = bwconncomp(bwmask,8);
    LHaloMask = labelmatrix(CC);
    num = max(LHaloMask(:));
    for n = 1:num
        pix = find(LHaloMask==n & ~locbwHalo);
        level = graythresh(locIm(pix));
        bwpix = im2bw(locIm(pix),level);
        locbwDark(pix(find(~bwpix)))=1;
    end
    
    bwDark = false(size(im));
    bwDark(ylims(1):ylims(2),xlims(1):xlims(2)) = locbwDark;
    
    bwig = false(size(im));
    bwig(ylims(1):ylims(2),xlims(1):xlims(2)) = locbwig;
    
    bwHalo = false(size(im));
    bwHalo(ylims(1):ylims(2),xlims(1):xlims(2)) = locbwHalo;
end