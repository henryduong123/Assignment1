function [bwDark bwDarkCenters bwig bwHalo] = SegDarkCenters(t, imageAlpha)
    global CONSTANTS
    
%     persistent cachedArg cachedRes
%     
%     cacheSize = 2;
%     if ( isempty(cachedRes) )
%         cachedRes = struct('bwDark', cell(1,cacheSize), 'bwDarkCenters', cell(1,cacheSize), 'bwig', cell(1,cacheSize), 'bwHalo', cell(1,cacheSize));
%     end
%     
%     % Assumes imageAlpha on [0,2]
%     argChk = t + (imageAlpha / 3);
%     
%     % Check cache for arguments
%     cacheIdx = find(cachedArg == argChk);
%     if ( ~isempty(cacheIdx) )
%         bwDark = cachedRes(cacheIdx).bwDark;
%         bwDarkCenters = cachedRes(cacheIdx).bwDarkCenters;
%         bwig = cachedRes(cacheIdx).bwig;
%         bwHalo = cachedRes(cacheIdx).bwHalo;
%     end
    
    fileName = [CONSTANTS.rootImageFolder CONSTANTS.datasetName '_t' SignificantDigits(t) '.TIF'];
    if exist(fileName,'file')
        [img colrMap] = imread(fileName);
    else
        img=zeros(CONSTANTS.imageSize);
    end
    im = mat2gray(img);
    
    % rerun part of seg
    level=imageAlpha*graythresh(im);
    bwHalo=im2bw(im,level);

    bwDark=false(size(im));
    seBig=strel('square',19);

    se=strel('square',3);
    gd=imdilate(im,se);
    ge=imerode(im,se);
    ig=gd-ge;
    lig=graythresh(ig);
    bwig=im2bw(ig,lig);

    bwmask=imclose(bwig,seBig);
    % find dark chewy centers
    CC = bwconncomp(bwmask,8);
    LHaloMask = labelmatrix(CC);
    num=max(LHaloMask(:));
    for n=1:num
        pix=find(LHaloMask==n & ~bwHalo);
        level=graythresh(im(pix));
        bwpix=im2bw(im(pix),level);
        bwDark(pix(find(~bwpix)))=1;
    end

    bwDarkCenters=(bwDark & bwmask );
    d=bwdist(~bwDarkCenters);
    bwDarkCenters(d<2)=0;
    
%     % Update last cacheSlot
%     if ( length(cachedArg) < cacheSize )
%         cachedArg(end+1) = argChk;
%     else
%         for i=2:length(cachedArg)
%             cachedArg(i-1) = cachedArg(i);
%             cachedRes(i-1) = cachedRes(i);
%         end
%         cachedArg(end) = argChk;
%     end
%     
%     cachedRes(length(cachedArg)).bwDark = bwDark;
%     cachedRes(length(cachedArg)).bwDarkCenters = bwDarkCenters;
%     cachedRes(length(cachedArg)).bwig = bwig;
%     cachedRes(length(cachedArg)).bwHalo = bwHalo;
end