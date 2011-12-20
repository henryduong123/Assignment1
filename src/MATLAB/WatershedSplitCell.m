function [newHulls newFeatures] = WatershedSplitCell(cell, cellFeat, k)
    global CONSTANTS
    
    fileName = [CONSTANTS.rootImageFolder CONSTANTS.datasetName '_t' SignificantDigits(cell.time) '.TIF'];
    if exist(fileName,'file')
        [img colrMap] = imread(fileName);
    else
        img=zeros(CONSTANTS.imageSize);
    end
    imgray = mat2gray(img);

    newHulls = [];
    newFeatures = [];

    [r c] = ind2sub(CONSTANTS.imageSize,cell.indexPixels);
    [polyr polyc] = ind2sub(CONSTANTS.imageSize,cellFeat.polyPix);
    
    xlims = clamp([min(c)-5 max(c)+5], 1, CONSTANTS.imageSize(2));
    ylims = clamp([min(r)-5 max(r)+5], 1, CONSTANTS.imageSize(1));
    
    locr = r - ylims(1);
    locc = c - xlims(1);
    
    locpolyr = polyr - ylims(1);
    locpolyc = polyc - xlims(1);
    
    locsz = [ylims(2)-ylims(1) xlims(2)-xlims(1)]+1;
    
    locind = sub2ind(locsz, locr, locc);
    
    locbw = false(locsz);
    locbw(locind) = 1;
    
    D = -bwdist(~locbw);

%     h = prctile(D(locbw),5) - min(D(locbw));
%     D = imhmin(D, h);

    D(~locbw) = -Inf;
    L = watershed(D);
    
    figure;imagesc(L);colormap(gray);hold on;

    kmins = Inf*ones(1,k);
    kidx = zeros(1,k);
    centers = zeros(k,2);
    for i=1:max(L(:))
        pix = find(L==i);
        [minpix pxidx] = min(D(pix));
        if ( isinf(minpix) )
            continue;
        end
        
        [pxr,pxc] = ind2sub(size(L),pix(pxidx));
        
        tmpmin = [kmins minpix];
        tmpidx = [kidx i];
        tmpctr = [centers; pxr pxc];
        
        [dump srtidx] = sort(tmpmin);
        kmins = tmpmin(srtidx(1:k));
        kidx = tmpidx(srtidx(1:k));
        centers = tmpctr(srtidx(1:k),:);
    end
    
    if ( any(isinf(kmins)) )
        return;
    end
    
    locdist = Inf*ones(length((locr)),k);
    for i=1:k
%         [tmpr tmpc] = find(L==kidx(i));
%         centers(i,:) = mean([tmpr tmpc],1);
        
        locdist(:,i) = ((locr-centers(i,1)).^2 + (locc-centers(i,2)).^2);
        polydist(:,i) = ((locpolyr-centers(i,1)).^2 + (locpolyc-centers(i,2)).^2);
    end
    
    [dump,ptidx] = min(locdist,[],2);
    [dump,polyidx] = min(polydist,[],2);
    
    [bwDark bwDarkCenters bwig bwHalo] = segDarkCenters(imgray, CONSTANTS.imageAlpha);
    
    cmap = hsv(k);
    for i=1:k
        pts = [locr(ptidx==i) locc(ptidx==i)];
        plot(pts(:,2),pts(:,1), '.', 'Color',cmap(i,:));
        
        polypts = [locpolyr(polyidx==i) locpolyc(polyidx==i)];
%         bLocal = (polypts(:,1)>0 & polypts(:,2)>0);
%         polypts = polypts(bLocal,:);
%         plot(polypts(:,2),polypts(:,1), 'o', 'Color',cmap(i,:));
        
        hullr = r(ptidx==i);
        hullc = c(ptidx==i);
        
        com = mean([hullr hullc],1);
        ch = convhull(hullr, hullc);
        pts = [hullc(ch) hullr(ch)];
        idxPix = cell.indexPixels(ptidx==i);
        imPix = cell.imagePixels(ptidx==i);
        
        nh = struct('time',{cell.time}, 'points',{pts}, 'centerOfMass',{com}, 'indexPixels',{idxPix}, 'imagePixels',{imPix}, 'deleted',{0}, 'userEdited',{0});
        newHulls = [newHulls nh];
        
        nf = [];
        
        if ( cellFeat.brightInterior )
            nf.darkRatio = nnz(bwDark(pix)) / length(pix);
            nf.haloRatio = HaloRat;
            nf.igRatio = igRat;
            nf.darkIntRatio = DarkRat;
            nf.brightInterior = 0;

            nf.polyPix = polyPix;
            nf.perimPix = perimPix;
            nf.igPix = find(bwig(perimPix));
            nf.haloPix = find(bwHalo(perimPix));
        else
            polyPix = cellFeat.polyPix(polyidx==i);
            perimPix = BuildPerimPix(polyPix, CONSTANTS.imageSize);
            
            [tr tc] = ind2sub(CONSTANTS.imageSize, perimPix);
            loctr = tr - ylims(1);
            loctc = tc - xlims(1);
            
%             bLocal = (loctr>0 & loctc>0);
%             loctr = loctr(bLocal);
%             loctc = loctc(bLocal);
            
%             plot(loctc,loctr, '.', 'Color',[0 1 0])

            igRat = nnz(bwig(perimPix)) / length(perimPix);
            HaloRat = nnz(bwHalo(perimPix)) / length(perimPix);

            bwDarkInterior = bwDarkCenters(polyPix);
            DarkRat = nnz(bwDarkInterior) / length(polyPix);

            %
            nf.darkRatio = nnz(bwDark(idxPix)) / length(idxPix);
            nf.haloRatio = HaloRat;
            nf.igRatio = igRat;
            nf.darkIntRatio = DarkRat;
            nf.brightInterior = 0;

            nf.polyPix = polyPix;
            nf.perimPix = perimPix;
            nf.igPix = find(bwig(perimPix));
            nf.haloPix = find(bwHalo(perimPix));
        end
        
        newFeatures = [newFeatures nf];
    end
end

function x_clamped = clamp(x, minval, maxval)
    x_clamped = max(cat(3,x,minval*ones(size(x))),[],3);
    x_clamped = min(cat(3,x_clamped,maxval*ones(size(x))),[],3);
end

function [bwDark bwDarkCenters bwig bwHalo] = segDarkCenters(im, imageAlpha)
    % rerun part of seg
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
end