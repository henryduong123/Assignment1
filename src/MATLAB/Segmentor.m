% Segmentor.m - Cell image segmentation algorithm.
% Segmentor is to be run as a seperate compiled function for parallel
% processing.  It will process tLength-tStart amount of images.  Call this
% function for the number of processors on the machine.

% mcc -o Segmentor -m Segmentor.m

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

function objs = Segmentor(tStart,tStep,tEnd,rootImageFolder,datasetName,imageAlpha,imageSignificantDigits)

objs=[];
if(ischar(tStart)),tStart = str2double(tStart);end
if(ischar(tStep)),tStep = str2double(tStep);end
if(ischar(tEnd)),tEnd = str2double(tEnd);end
if(ischar(imageAlpha)),imageAlpha = str2double(imageAlpha);end
if(ischar(imageSignificantDigits)),imageSignificantDigits = str2double(imageSignificantDigits);end

numImages = tEnd/tStep;

for t = tStart:tStep:tEnd
    switch imageSignificantDigits
        case 3
            frameT = num2str(t,'%03d');
        case 4
            frameT = num2str(t,'%04d');
        case 5
            frameT = num2str(t,'%05d');
        case 6
            frameT = num2str(t,'%06d');
    end
    fname=[rootImageFolder '\' datasetName '_t' frameT '.TIF'];
    if(isempty(dir(fname))),continue,end
    
    fprintf('%d%%...',floor(floor(t/tStep)/numImages*100));
    
    [im map]=imread(fname);
    % Handle "color" images by averaging the color channels to get
    % intensity (should all be the same for all channels)
    if ( ndims(im) > 2 )
        im = mean(im,3);
    end
    
    im=mat2gray(im);
    
    bwDark=0*im;
    level=imageAlpha*graythresh(im);
    bwHalo=im2bw(im,level);
    
    l2=graythresh(im);
    pix=im(im<l2);
    lDark=graythresh(pix);
    bwDark(im<lDark)=1;
    
    bwNorm=0*bwDark;
    se=strel('square',3);
    gd=imdilate(im,se);
    ge=imerode(im,se);
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
    
    num=max(LCenters(:));
    for n=1:num
        pix=find(LCenters==n);
        if length(pix)<50
            bwCells(pix)=0;
            continue
        end
        
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
        if  HaloRat>0.5   || igRat<.1 ||(DarkRat<.5 && igRat<.5 && length(pix)<175)
            bwCells(pix)=0;
            continue
        end
        dmax=max(d(pix));
        if dmax>4
            bwCells(pix(d(pix)<2))=0;
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
        if length(find(im(pix)>lDark))/length(pix)> 0.5
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
    end
end

fileName = ['.\segmentationData\objs_' num2str(tStart) '.mat'];
if(isempty(dir('.\segmentationData'))),system('mkdir .\segmentationData');end
save(fileName,'objs');

fprintf('\tDone\n');
end