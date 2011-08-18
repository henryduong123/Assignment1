%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
%     Copyright 2011 Andrew Cohen, Eric Wait and Mark Winter
%
%     This file is part of LEVer - the tool for stem cell lineaging. See
%     https://pantherfile.uwm.edu/cohena/www/LEVer.html for details
% 
%     LEVer is free software: you can redistribute it and/or modify
%     it under the terms of the GNU General Public License as published by
%     the Free Software Foundation, either version 3 of the License, or
%     (at your option) any later version.
% 
%     LEVer is distributed in the hope that it will be useful,
%     but WITHOUT ANY WARRANTY; without even the implied warranty of
%     MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
%     GNU General Public License for more details.
% 
%     You should have received a copy of the GNU General Public License
%     along with LEVer in file "gnu gpl v3.txt".  If not, see 
%     <http://www.gnu.org/licenses/>.
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function hull = PartialImageSegment(img, centerPt, subSize, alpha)
    
    if ( length(subSize) < 2 )
        subSize = [subSize(1) subSize(1)];
    end
    
    imSize = size(img);
    
    coordMin = floor([centerPt(1)-subSize(1)/2 centerPt(2)-subSize(2)/2]);
    coordMin(coordMin < 1) = 1;
    
    coordMax = ceil([centerPt(1)+subSize(1)/2 centerPt(2)+subSize(2)/2]);
    if ( coordMax(1) > imSize(2) )
        coordMax(1) = imSize(2);
    end
    if ( coordMax(2) > imSize(1) )
        coordMax(2) = imSize(1);
    end
    
    % Build the subimage to be segmented
    subImg = img(coordMin(2):coordMax(2), coordMin(1):coordMax(1));
    
%     hold off;figure;imagesc(subImg);colormap(gray);hold on;
    
    objs = [];
    
    se=strel('square',3);
    
    bwDark=0*subImg;
    level=alpha*graythresh(subImg);
    bwHalo=im2bw(subImg,level);

    l2=graythresh(subImg);
    pix=subImg(subImg<l2);
    lDark=graythresh(pix);
    bwDark(subImg<lDark)=1;
    
    bwNorm=0*bwDark;

    gd=imdilate(subImg,se);
    ge=imerode(subImg,se);
    ig=gd-ge;
    lig=graythresh(ig);
    bwig=im2bw(ig,lig);
    seBig=strel('square',19);
    bwmask=imclose(bwig,seBig);
    
    bwDarkCenters=(bwDark & bwmask );
    d=bwdist(~bwDarkCenters);
    bwDarkCenters(d<2)=0;
    
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
    
    bwCells=bwDarkCenters| bwHoles|bwNorm;
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
    
%     [tr,tc] = find(LCenters>0);
%     plot(tc,tr,'.r');
    
    num=max(LCenters(:));
    for n=1:num
        pix=find(LCenters==n);
        if length(pix)<50
            bwCells(pix)=0;
            continue
        end
        
        bwPoly=logical(0*subImg);
        bwPoly(pix)=1;
        bwPoly=bwmorph(bwPoly,'dilate',1);
        p=bwperim(bwPoly);
        
        igRat=length(find(p & bwig))/length(find(p));
    
        HaloRat=length(find(p & bwHalo))/length(find(p));

        [r c]=ind2sub(size(subImg),pix);
        ch=convhull(r,c);

        bwDarkInterior=bwDarkCenters&bwPoly;
        DarkRat=length(find(bwDarkInterior))/length(find(bwPoly));
%         if  HaloRat>0.5   || igRat<.1 ||(DarkRat<.5 && igRat<.5 && length(pix)<175)
%             bwCells(pix)=0;
%             continue
%         end
        dmax=max(d(pix));
        if dmax>4
            bwCells(pix(d(pix)<2))=0;
        end
    end
    
    bwCellFG=0*bwCells;

    CC = bwconncomp(bwCells,8);
    LCenters = labelmatrix(CC);
    
%     [tr,tc] = find(LCenters>0);
%     plot(tc,tr,'og');

%     hold off;figure;imagesc(subImg);colormap(gray);hold on;
    
    stats=regionprops(CC,'area','Eccentricity');
    idx = find([stats.Area] >=25);
    for i=1:length(idx)
        pix=find(LCenters==idx(i));
        if length(pix)<20
            continue
        end
        [r c]=ind2sub(size(subImg),pix);
        bwPoly=roipoly(subImg,c,r);
        if bwarea(bwPoly)<1
            continue
        end

        ch=convhull(r,c);
        % one  last check for parasites 
        if length(find(subImg(pix)>lDark))/length(pix)> 0.5
            continue 
        end
        % it's a keeper!
        bwCellFG(pix)=1;

%         plot(c(ch),r(ch),'-r','linewidth',1.5)
        
        glc = c + coordMin(1);
        glr = r + coordMin(2);

        no=[];
        no.points=[glc(ch),glr(ch)];
        no.centerOfMass = mean([glr glc]);

        %no.indPixels=pix;
        no.indexPixels = sub2ind(imSize, glr,glc);
        no.imagePixels=img(no.indexPixels);
        % surround completely by Halo?
        if all(bwHaloHoles(pix))
            no.BrightInterior=1;
        else
            no.BrightInterior=0;
        end
        
        no.ID=-1;
        no.Eccentricity=stats(idx(i)).Eccentricity;
        objs = [objs no];
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
		pix = find(Ligm==idx(i));
		[r c] = ind2sub(size(subImg),pix);
		ch = convhull(r,c);
		
		bwPoly = poly2mask(c(ch),r(ch),size(subImg,1),size(subImg,2));
		if length(find(bwCellFG & bwPoly))
            continue;
        end
        
        glc = c + coordMin(1);
        glr = r + coordMin(2);
        
		no=[];
        
		no.points=[glc(ch),glr(ch)];
		no.centerOfMass = mean([glr glc]);
        
		no.indexPixels = sub2ind(imSize, glr,glc);
        no.imagePixels=img(no.indexPixels);
        
        no.ID=-1;
		no.BrightInterior=1;
		no.Eccentricity=stats(idx(i)).Eccentricity;
		objs=[objs no];
	end
    
    bInHull = CHullContainsPoint(centerPt, objs);
    
    hull = objs(find(bInHull,1));
end

