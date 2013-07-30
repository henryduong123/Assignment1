function [objs features levels] = FrameSegmentor(im, t, imageAlpha)
    objs = [];
    features = [];
    levels = struct('haloLevel',{[]}, 'igLevel',{[]});
    
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
        
        % one last check for parasites
        if length(find(bwDark(pix)))/length(pix)< 0.4
%             plot(c(ch),r(ch),'-c')
            continue
        end
        % it's a keeper!
        bwCellFG(pix)=1;
        
        no=[];
        no.t=t;
        no.points=[c(ch),r(ch)]; % ACK MARK HACK HACK
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
        
        oldPix = find(LCenters==oldLbl);
        newLbls = unique(LCells(oldPix));
        newLbls = newLbls(newLbls > 0);

        if ( length(newLbls) > 1 )
            lblPix = cell(1,length(newLbls));
            for j=1:length(newLbls)
                lblPix{j} = find(LCells == newLbls(j));
            end

            polyIdx = Segmentation.AssignPolyPix(polyPix, lblPix, size(im));
        else
            polyIdx = ones(length(polyPix),1);
        end
        
        curIdx = find(newLbls==idx(i));
        
        polyPix = polyPix(polyIdx==curIdx);
        perimPix = Segmentation.BuildPerimPix(polyPix, size(im));
        
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
        %no.pts=[c(ch),r(ch)];
        no.points=[c(ch),r(ch)]; % ACK MARK HACK HACK
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
        
        nf.polyPix = find(bwPoly);
        nf.perimPix = [];
        nf.igPix = [];
        nf.haloPix = [];
        
        objs=[objs no];
        features = [features nf];
    end
    
    % hemato submarines
%    [sharpImg blurImg bw] = michelContrastEnhance(1-im);
    [bw] = Segmentation.Michel(1-im, [3 3]);
    
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
