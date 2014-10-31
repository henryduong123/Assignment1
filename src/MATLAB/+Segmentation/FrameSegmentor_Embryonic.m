function [objs features levels] = FrameSegmentor_Embryonic(chanIm, t, imageAlpha)
    objs = [];
    features = [];
    levels = struct('haloLevel',{0}, 'igLevel',{0});
    
    if ( length(chanIm) > 1 )
        fprintf('WARNING: Multichannel segmentation not supported by this algorithm, using channel 1\n');
    end
    
    im = chanIm{1};
    if ( isempty(im) )
        return;
    end
    
    level=imageAlpha*graythresh(im);
    
    level = min(level,0.95);
    level = max(level,0.05);
    
    bwHalo=im2bw(im,level);
    
    bwDark=0*im;

    bwNorm=0*bwDark;
    se=strel('square',3);
    gd=imdilate(im,se);
    ge=imerode(im,se);
    ig=gd-ge;
    lig=graythresh(ig);
    bwig=im2bw(ig,lig);
    seBig=strel('square',19);
    bwmask=imclose(bwig,seBig);
    
    l2=graythresh(im);
    pix=im(im<l2);
    lDark=graythresh(pix);
    bwDark(im<lDark)=1;

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
    bwCells=bwDarkCenters | bwHoles | bwNorm;
    bwCells(~bwHaloMask)=0;
    
    CC = bwconncomp(bwHalo,8);
    LCells = labelmatrix(CC);
    
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
            continue
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
        if length(find(im(pix)>lDark))/length(pix)> 0.5
            continue
        end
        % it's a keeper!
        bwCellFG(pix)=1;
        
        no=[];
        no.t=t;
        no.points = [c(ch),r(ch)];
        
        no.indPixels=pix;
        if LTails(r(1),c(1))
            TailPix = find(LTails==LTails(r(1),c(1)));
            TailPix=union(TailPix,pix);
        else
            TailPix=pix;
        end
        no.indTailPixels=TailPix;
        no.imPixels=im(pix);
        
        % surround completely by Halo?
        if all(bwHaloHoles(pix))
            no.BrightInterior=1;
        else
            no.BrightInterior=0;
        end
        
        no.ID=-1;
        no.Eccentricity=stats(idx(i)).Eccentricity;
        
        nf = [];
        nf.darkRatio = 0;
        nf.haloRatio = 0;
        nf.igRatio = 0;
        nf.darkIntRatio = 0;
        nf.brightInterior = 0;
        
        nf.polyPix = find(bwPoly);
        nf.perimPix = [];
        nf.igPix = [];
        nf.haloPix = [];
        
        objs = [objs no];
        features = [features nf];
        %     drawnow
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
        no=[];
        no.t=t;
        
        no.points=[c(ch),r(ch)];
        no.ID=-1;
        
        no.indPixels=pix;
        if LTails(r(1),c(1))
            TailPix = find(LTails==LTails(r(1),c(1)));
            TailPix=union(TailPix,pix);
        else
            TailPix=pix;
        end
        no.indTailPixels=TailPix;
        no.BrightInterior=1;
        no.Eccentricity=stats(idx(i)).Eccentricity;
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
        
        objs = [objs no];
        features = [features nf];
    end
end
