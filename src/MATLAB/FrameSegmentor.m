function [objs features] = FrameSegmentor(im, t, imageAlpha)
    objs = [];
    features = [];
    
    % Handle "color" images by averaging the color channels to get
    % intensity (should all be the same for all channels)
    if ( ndims(im) > 2 )
        im = mean(im,3);
    end
    
    im=mat2gray(im);
    
    level=imageAlpha*graythresh(im);
    bwHalo=im2bw(im,level);
    
    bwDark=0*im;
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
    bwCells=bwDarkCenters| bwHoles;
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
        ch = convhull(r,c);
        
        bwDarkInterior = bwDarkCenters & bwPoly;
        DarkRat = length(find(bwDarkInterior)) / length(find(bwPoly));
        if  ( HaloRat>0.5   || igRat<.1 || (DarkRat < 0.5 && igRat < 0.5 && length(pix) < 175) )
            bwCells(pix)=0;
            continue;
        end
        
        LPolyPix{n} = find(bwPoly);
        LPerimPix{n} = find(p);
        
        dmax=max(d(pix));
        if dmax>4
            bwCells(pix(d(pix)<2))=0;
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
        
        ch=convhull(r,c);
        
        % one  last check for parasites
        if length(find(bwDark(pix)))/length(pix)< 0.4
%             plot(c(ch),r(ch),'-c')
            continue
        end
        % it's a keeper!
        bwCellFG(pix)=1;
        
        no=[];
        no.t=t;
        no.pts=[c(ch),r(ch)];
        
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
        
        % object features
        oldLbl = LCenters(pix(1));
        
        polyPix = LPolyPix{oldLbl};
        [polyR polyC] = ind2sub(size(im), polyPix);
        
        perimPix = LPerimPix{oldLbl};
        [perimR perimC] = ind2sub(size(im), perimPix);
        
        oldPix = find(LCenters==oldLbl);
        newLbls = unique(LCells(oldPix));
        newLbls = newLbls(newLbls > 0);
        centroid = [];
        
        polyDist = Inf*ones(length(polyR),length(newLbls));
%         perimDist = Inf*ones(length(perimR),length(newLbls));
        for j=1:length(newLbls)
            [newR newC] = find(LCells == newLbls(j));
            centroid = mean([newR newC],1);
            
            polyDist(:,j) = ((polyR - centroid(1)).^2 + (polyC - centroid(2)).^2);
%             perimDist(:,j) = ((perimR - centroid(1)).^2 + (perimC - centroid(2)).^2);
        end
        
        [mpd polyIdx] = min(polyDist,[],2);
%         [mpd perimIdx] = min(perimDist,[],2);
        
        curIdx = find(newLbls==idx(i));
        
        polyPix = polyPix(polyIdx==curIdx);
        perimPix = BuildPerimPix(polyPix, size(im));
        
        igRat = nnz(bwig(perimPix)) / length(perimPix);
        HaloRat = nnz(bwHalo(perimPix)) / length(perimPix);
        
        bwDarkInterior = bwDarkCenters(polyPix);
        DarkRat = nnz(bwDarkInterior) / length(polyPix);
        
        nf = [];
        nf.darkRatio = nnz(bwDark(pix)) / length(pix);
        nf.haloRatio = HaloRat;
        nf.igRatio = igRat;
        nf.darkIntRatio = DarkRat;
        nf.brightInterior = 0;
        
        nf.polyPix = polyPix;
        nf.perimPix = perimPix;
        nf.igPix = find(bwig(perimPix));
        nf.haloPix = find(bwHalo(perimPix));
        
        objs=[objs no];
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
        ch=convhull(r,c);
        
        bwPoly = poly2mask(c(ch),r(ch),size(im,1),size(im,2));
        if ~isempty(find(bwCellFG &bwPoly, 1)),continue,end
        no=[];
        no.t=t;
        no.pts=[c(ch),r(ch)];
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
        
        nf.haloRatio = 0;
        nf.igRatio = 0;
        nf.darkIntRatio = 0;
        nf.darkRatio = 0;
        nf.brightInterior = 1;
        
        nf.polyPix = find(bwPoly);
        nf.perimPix = [];
        nf.igPix = [];
        nf.igPix = [];
        
        objs=[objs no];
        features = [features nf];
    end
end