% FrameSegmentor_Adult - Algorithm for identifying adult neural progenitor cells imaged using phase contrast microscopy.
% 
% hulls = FrameSegmentor_Adult(chanIm, primaryChan, t, imageAlpha)
% INPUTS:
%   chanIm - A cell array each chanIm{i} contains the image intensity date 
%   for the i-th channel at frame t. Some cells may be empty if they were 
%   unavailable or not imaged at frame t.
% 
%   primaryChan - A number between 1 and CONSTANTS.numChannels indicating
%   the primary channel for the segmentation. Specific algorithms may use
%   information from other available channels as well.
% 
%   t - The frame number of the image data being passed into the
%   segmentation algorithm.
% 
%   imageAlpha - A multiplier on the threshold used to detect the phase constrast "halo" surrounding cells.
%   Increasing the imageAlpha multiplier will usually result in fewer cell segmentation results.
% 
% OUTPUTS:
%   hulls - The hulls output is a structure array with one entry per segmentation result.
%   For more information on the output format see Segmentation.FrameSegmentor.
% 
% See also Segmentation.FrameSegmentor.
% 
function hulls = FrameSegmentor_Adult(chanIm, primaryChan, t, imageAlpha)
    hulls = [];
    levels = struct('haloLevel',{[]}, 'igLevel',{[]});
    
    im = chanIm{primaryChan};
    if ( isempty(im) )
        return;
    end
    
    
    levels.haloLevel = graythresh(im);
    level=imageAlpha*levels.haloLevel;
    
    level = min(level,0.95);
    level = max(level,0.05);
    
    bwHalo=im2bw(im,level);
    
    bwDark=0*im;
    seBig=strel('square',19);
    
    se=strel('square',3);
    gd=imdilate(im,se);
    ge=imerode(im,se);
    ig=gd-ge;
    levels.igLevel = graythresh(ig);
    lig=levels.igLevel;
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

    bwHaloMask=imdilate(bwHalo,seBig);
    
    bwHaloHoles=imfill(bwHalo ,8,'holes') & ~bwHalo;
    bwDarkHoles=imfill(bwDarkCenters ,8,'holes') & ~bwDarkCenters;
    bwgHoles=bwmorph(bwig | bwDarkCenters,'close',1) ;
    bwgHoles=imfill(bwgHoles ,8,'holes') & ~(bwig | bwDarkCenters);
    
    bwHoles=bwHaloHoles | bwDarkHoles | bwgHoles;
    
    CC = bwconncomp(bwHoles,8);
    LHoles = labelmatrix(CC);
    stats = regionprops(CC, 'Area');
    idx = find([stats.Area] < 500);
    bwHoles = ismember(LHoles, idx);
    bwCells=bwDarkCenters | bwHoles;
    bwCells(~bwHaloMask)=0;
    
    bwCells(bwig)=0;
    
    bwTails=bwDarkCenters;
    bwTails(bwHalo)=0;
    CC = bwconncomp(bwTails,8);
    LTails = labelmatrix(CC);
    
    CC = bwconncomp(bwCells,8);
    LCenters = labelmatrix(CC);
    stats=regionprops(CC,'eccentricity');
    d=bwdist(~bwCells);
    
    LPolyPix = [];
    LPerimPix = [];
    
    num=max(LCenters(:));
    for n=1:num
        pix=find(LCenters==n);
        if length(pix)<50
            bwCells(pix)=0;
            continue
        end
        
        bwPoly = logical(0*im);
        bwPoly(pix) = 1;
        bwPoly = bwmorph(bwPoly,'dilate',1);
        p = bwperim(bwPoly);
        
        igRat = length(find(p & bwig)) / length(find(p));
        
        HaloRat = length(find(p & bwHalo)) / length(find(p));
        
        [r c] = ind2sub(size(im),pix);
        
        bwDarkInterior = bwDarkCenters & bwPoly;
        DarkRat = length(find(bwDarkInterior)) / length(find(bwPoly));
        if ( HaloRat > 0.5   || igRat < 0.1 || (DarkRat < 0.5 && igRat < 0.5 && length(pix) < 175) )
            bwCells(pix)=0;
            continue;
        end
        
        LPolyPix{n} = find(bwPoly);
        LPerimPix{n} = find(p);
        
        dmax=max(d(pix));
        if dmax>4
            bwCells(pix(d(pix)<2)) = 0;
            continue;
        end
    end
    
    
    bwCellFG=0*bwCells;
    
    CC = bwconncomp(bwCells,8);
    LCells = labelmatrix(CC);
    stats=regionprops(CC,'area','Eccentricity');
    idx = find([stats.Area] >=25);
    for i=1:length(idx)
        pix=find(LCells==idx(i));
        if length(pix)<20
            continue
        end
        [r c]=ind2sub(size(im),pix);
        bwPoly=roipoly(im,c,r);
        if bwarea(bwPoly)<1
            continue
        end
        
        ch = Helper.ConvexHull(c,r);
        
        % one  last check for parasites
        if length(find(bwDark(pix)))/length(pix)< 0.4
%             plot(c(ch),r(ch),'-c')
            continue
        end
        % it's a keeper!
        bwCellFG(pix)=1;
        
        newHull = [];
        newHull.time = t;
        newHull.points = [c(ch),r(ch)];
        newHull.indexPixels = pix;
        
        newHull.tag = 'darkInterior';
        
        hulls = [hulls newHull];
    end
    
    % bright interiors
    igm=bwig|bwHalo;
    se=strel('square',5);
    igm=imclose(igm,se);
    igm=imfill(igm,'holes');
    igm(logical(bwCellFG))=0;
    se=strel('square',13);
    igm=imerode(igm,se);
    
    CC = bwconncomp(igm,8);
    Ligm = labelmatrix(CC);
    stats = regionprops(CC, 'Area','Eccentricity');
    idx = find( [stats.Area] >25 & [stats.Area] <1000 & [stats.Eccentricity]<.95 ) ;
    
    for i=1:length(idx)
        pix=find(Ligm==idx(i));
        [r c]=ind2sub(size(im),pix);
        ch = Helper.ConvexHull(c,r);
        
        bwPoly = poly2mask(c(ch),r(ch),size(im,1),size(im,2));
        if ~isempty(find(bwCellFG &bwPoly, 1)),continue,end
        
        newHull = [];
        newHull.time = t;
        newHull.points = [c(ch),r(ch)];
        newHull.indexPixels = pix;
        
        newHull.tag = 'brightnterior';
        
        hulls = [hulls newHull];
    end
end
