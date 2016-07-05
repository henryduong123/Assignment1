% FrameSegmentor_Embryonic - Algorithm for identifying embryonic neural progenitor cells imaged using phase contrast microscopy.
% 
% hulls = FrameSegmentor_Embryonic(chanIm, primaryChan, t, imageAlpha)
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

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
%     Copyright 2011-2016 Andrew Cohen
%
%     This file is part of LEVer - the tool for stem cell lineaging. See
%     http://n2t.net/ark:/87918/d9rp4t for details
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

function hulls = FrameSegmentor_Embryonic(chanIm, primaryChan, t, imageAlpha)
    hulls = [];
    
    im = chanIm{primaryChan};
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
        
        %TODO: Helper functions for hull, and other struct templates, so
        %that we don't have to deal with structure integrity issues.
        newHull = [];
        newHull.time = t;
        newHull.points = [c(ch),r(ch)]; % ACK MARK HACK HACK
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
        if ( ~isempty(find(bwCellFG & bwPoly, 1)) )
            continue;
        end
        
                newHull = [];
        newHull.time = t;
        newHull.points = [c(ch),r(ch)]; % ACK MARK HACK HACK
        newHull.indexPixels = pix;
        
        newHull.tag = 'brightInterior';
        
        hulls = [hulls newHull];
    end
end
