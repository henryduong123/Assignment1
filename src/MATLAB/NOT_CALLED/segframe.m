function segframe(t, imageAlpha)

    global CONSTANTS

    fname=fullfile(CONSTANTS.rootImageFolder,[CONSTANTS.datasetName '_t' num2str(t,'%03d') '.TIF']);

    [im map]=imread(fname);
    im=mat2gray(im);
    
    figure(5);
    hold off;imagesc(im);colormap(gray);hold on;
    title(num2str(t));
    
    level=imageAlpha*graythresh(im);
    bwHalo=im2bw(im,level);
    
    [r c]=find(bwHalo);
    plot(c,r,'.y');
    
    bwDark=0*im;
    seBig=strel('square',19);
    bwHaloMask=imdilate(bwHalo,seBig);
    
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
    
    figure(6);imagesc(LHaloMask);
    
    bwDarkCenters=(bwDark & bwmask );
    d=bwdist(~bwDarkCenters);
    bwDarkCenters(d<2)=0;
    
    figure(5)
    
    [r c]=find(bwDarkCenters);
    plot(c,r,'.r');

    bwHaloMask=imdilate(bwHalo,seBig);
    
    bwHaloHoles=imfill(bwHalo ,8,'holes') & ~bwHalo;
    bwDarkHoles=imfill(bwDarkCenters ,8,'holes') & ~bwDarkCenters;
    bwgHoles=bwmorph(bwig | bwDarkCenters,'close',1) ;
    bwgHoles=imfill( bwgHoles ,8,'holes') & ~(bwig |bwDarkCenters);
    
    bwHoles=bwHaloHoles |bwDarkHoles|bwgHoles;
    
    CC = bwconncomp(bwHoles,8);
    LHoles = labelmatrix(CC);
    stats = regionprops(CC, 'Area');
    idx = find([stats.Area] < 500);
    bwHoles = ismember(LHoles, idx);
    
    [r c]=find(bwHoles);
    plot(c,r,'.c');
    
    bwCells=bwDarkCenters| bwHoles;
    bwCells(~bwHaloMask)=0;
    
    CC = bwconncomp(bwHalo,8);
    LCells = labelmatrix(CC);
    
    bwCells(bwig)=0;
    
    % bwTails=imdilate(bwDarkCenters,strel('square',3));
    bwTails=bwDarkCenters;
    bwTails(bwHalo)=0;
    CC = bwconncomp(bwTails,8);
    LTails = labelmatrix(CC);
    
    % [r c]=find(bwTails|bwCells);
    % plot(c,r,'.g')
    
    CC = bwconncomp(bwCells,8);
    LCenters = labelmatrix(CC);
    stats=regionprops(CC,'eccentricity');
    d=bwdist(~bwCells);
    
    num=max(LCenters(:));
    for n=1:num
        pix=find(LCenters==n);
        if length(pix)<50
            bwCells(pix)=0;
            continue
        end
        
        %     if length(find(bwDarkCenters(pix)))<1
        %         bwCells(pix)=0;
        %         continue
        %     end
        
        bwPoly=logical(0*im);
        bwPoly(pix)=1;
        bwPoly=bwmorph(bwPoly,'dilate',1);
        p=bwperim(bwPoly);
        
        
        igRat=length(find(p & bwig))/length(find(p));
        
        HaloRat=length(find(p & bwHalo))/length(find(p));
        
        [r c]=ind2sub(size(im),pix);
        ch=convhull(r,c);
        
        bwDarkInterior=bwDarkCenters&bwPoly;
        DarkRat=length(find(bwDarkInterior))/length(find(bwPoly));
        %         fprintf(1,'%d, %2.3f, %2.3f, %2.3f %d\n',n ,igRat, DarkRat,HaloRat,length(pix));
        if  HaloRat>0.5   || igRat<.1 ||(DarkRat<.5 && igRat<.5 && length(pix)<175)
            %         plot(c(ch),r(ch),'-y')
            bwCells(pix)=0;
            continue
        end
        dmax=max(d(pix));
        if dmax>4
            bwCells(pix(d(pix)<2))=0;
            %         bwCells(pix(find(d(pix)<2)))=0;
        end
        
    end
    
    
    bwCellFG=0*bwCells;
    
    CC = bwconncomp(bwCells,8);
    LCenters = labelmatrix(CC);
    stats=regionprops(CC,'area','Eccentricity');
    idx = find([stats.Area] >=25);
    for i=1:length(idx)
        pix=find(LCenters==idx(i));
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
        
        
        
        %     plot(c(ch),r(ch),'-r','linewidth',1.5)
        
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
        objs=[objs no];
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
        objs=[objs no];
        
        %     plot(c(ch),r(ch),'-m')
        %     plot(c(ch),r(ch),'-r','linewidth',1.5)
        %     drawnow
    end
end