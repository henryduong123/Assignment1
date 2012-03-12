function [newHulls newFeatures] = WatershedSplitCell(cellHull, cellFeat, k)
global CONSTANTS

newHulls = [];
newFeatures = [];

% if ( ~exist('smoothPct','var') )
%     smoothPct = 0;
% end

[r c] = ind2sub(CONSTANTS.imageSize,cellHull.indexPixels);

xlims = Clamp([min(c)-5 max(c)+5], 1, CONSTANTS.imageSize(2));
ylims = Clamp([min(r)-5 max(r)+5], 1, CONSTANTS.imageSize(1));

locr = r - ylims(1) + 1;
locc = c - xlims(1) + 1;

locsz = [ylims(2)-ylims(1) xlims(2)-xlims(1)]+1;

locind = sub2ind(locsz, locr, locc);

locbw = false(locsz);
locbw(locind) = 1;

D = -bwdist(~locbw);

% if ( smoothPct > 0 )
%     h = prctile(D(locbw),smoothPct) - min(D(locbw));
%     D = imhmin(D, h);
% end

D(~locbw) = -Inf;
L = watershed(D);

curLbl = 1;
fgIm = false(size(L));
fgL = zeros(size(L));
for i=0:max(L(:))
    pix = find(L==i);
    [minpix pxidx] = min(D(pix));
    if ( isinf(minpix) )
        continue;
    end
    
    if ( i > 0 )
        fgL(pix) = curLbl;
        curLbl = curLbl + 1;
    end
    fgIm(pix) = 1;
end

figure;imagesc(fgL);colormap(gray);hold on;
[rtst ctst] = find(locbw);
plot(ctst,rtst, 'or');

mergedL = dilateMergeRegions(k, fgL, locbw);
if ( isempty(mergedL) )
    return;
end

% [bwDark bwig bwHalo] = SegDarkCenters(cellHull.time,CONSTANTS.imageAlpha);

ptidx = mergedL(locind);

% cmap = hsv(k);
connComps = cell(1,k);
for i=1:k
%     pts = [locr(ptidx==i) locc(ptidx==i)];
%     plot(pts(:,2),pts(:,1), '.', 'Color',cmap(i,:));
    
    hullr = r(ptidx==i);
    hullc = c(ptidx==i);
    
%     plot(hullc,hullr, '.', 'Color',cmap(i,:));
    
    com = mean([hullr hullc],1);
    ch = convhull(hullr, hullc);
    pts = [hullc(ch) hullr(ch)];
    idxPix = cellHull.indexPixels(ptidx==i);
    imPix = cellHull.imagePixels(ptidx==i);
    
    connComps{i} = idxPix;
    
    nh = struct('time',{cellHull.time}, 'points',{pts}, 'centerOfMass',{com}, 'indexPixels',{idxPix}, 'imagePixels',{imPix}, 'deleted',{0}, 'userEdited',{0});
    newHulls = [newHulls nh];
end

% Calculate new features if passed in feature structure is valids
if ( isempty(cellFeat) )
    return;
end

center = [cellHull.centerOfMass(2) cellHull.centerOfMass(1)];
[bwDark bwig bwHalo] = PartialSegDarkCenters(center, cellHull.time, CONSTANTS.imageAlpha);

polyidx = AssignPolyPix(cellFeat.polyPix, connComps, CONSTANTS.imageSize);

% cmap = hsv(k);
for i=1:k
%     polypts = [locpolyr(polyidx==i) locpolyc(polyidx==i)];
%     bLocal = (polypts(:,1)>0 & polypts(:,2)>0);
%     polypts = polypts(bLocal,:);
%     plot(polypts(:,2),polypts(:,1), 'o', 'Color',cmap(i,:));
    
    nf = struct('darkRatio',{0}, 'haloRatio',{0}, 'igRatio',{0}, 'darkIntRatio',{0}, 'brightInterior',{0}, 'polyPix',{[]}, 'perimPix',{[]}, 'igPix',{[]}, 'haloPix',{[]});
    
    polyPix = cellFeat.polyPix(polyidx==i);
    perimPix = BuildPerimPix(polyPix, CONSTANTS.imageSize);
%     
%     [r c] = ind2sub(CONSTANTS.imageSize, polyPix);
%     plot(c,r, '.', 'Color',cmap(i,:));
%     
%     [r c] = ind2sub(CONSTANTS.imageSize, perimPix);
%     plot(c,r, 'o', 'Color',cmap(mod(i,k)+1,:));
    
%     [tr tc] = ind2sub(CONSTANTS.imageSize, perimPix);
%     loctr = tr - ylims(1);
%     loctc = tc - xlims(1);
% 
%     bLocal = (loctr>0 & loctc>0);
%     loctr = loctr(bLocal);
%     loctc = loctc(bLocal);
% 
%     plot(loctc,loctr, '.', 'Color',[0 1 0])
    
    igRat = nnz(bwig(perimPix)) / length(perimPix);
    HaloRat = nnz(bwHalo(perimPix)) / length(perimPix);
    
%     bwDarkInterior = bwDarkCenters(polyPix);
%     DarkRat = nnz(bwDarkInterior) / length(polyPix);
    DarkRat = length(newHulls(i).indexPixels) / length(polyPix);
    
    %
    idxPix = newHulls(i).indexPixels;
    nf.darkRatio = nnz(bwDark(idxPix)) / length(idxPix);
    nf.haloRatio = HaloRat;
    nf.igRatio = igRat;
    nf.darkIntRatio = DarkRat;
    
    
    nf.polyPix = polyPix;
    nf.perimPix = perimPix;
    nf.igPix = find(bwig(perimPix));
    nf.haloPix = find(bwHalo(perimPix));
    
    if ( cellFeat.brightInterior )
        nf.brightInterior = 1;
    else
        nf.brightInterior = 0;
    end
    nf.polyPix = polyPix;
    nf.perimPix = perimPix;
    nf.igPix = find(bwig(perimPix));
    nf.haloPix = find(bwHalo(perimPix));
    newFeatures = [newFeatures nf];

end

end

function mergedL = dilateMergeRegions(k, L, bwIm)
    mergedL = [];
    
    numRegions = nnz(unique(L(bwIm))>0);
    if ( numRegions < k )
        return;
    end
    
%     if ( numRegions == k )
%         mergedL = cleanupComponents(L);
%     end

    bwMergeBound = false(size(bwIm));
    dg = zeros(numRegions,numRegions);
    mg = Inf*ones(numRegions,numRegions);

    bDilated = false(1,numRegions);
    
    dist = 1;
    se = strel('disk',1);
    while ( ~all(bDilated) )
        for i=1:numRegions
            if ( bDilated(i) )
                continue;
            end
            
            bwL = imdilate((L==i),se) & bwIm & ~bwMergeBound;
            chkMerge = unique(L(bwL));
            chkMerge = chkMerge(chkMerge > 0);
            mergeRgn = chkMerge(chkMerge ~= i);
            for j=1:length(mergeRgn)
                bwNewMB = (bwL & (L == mergeRgn(j)));
                bwMergeBound = bwMergeBound | bwNewMB;
                mg(i,mergeRgn(j)) = min(mg(i,mergeRgn(j)),dist);
                mg(mergeRgn(j),i) = mg(i,mergeRgn(j));
                
                dg(i,mergeRgn(j)) = dg(i,mergeRgn(j)) + nnz(bwNewMB);
                dg(mergeRgn(j),i) = dg(i,mergeRgn(j));
            end
            
            bwL(bwMergeBound) = 0;
            if ( all(L(bwL)==i) )
                bDilated(i) = 1;
            end
            
            L(bwL) = i;
            L(bwMergeBound) = 0;
        end
        dist = dist + 1;
    end
    
%     figure();imagesc(L);colormap(gray);
%     [r c] = find(bwMergeBound);
%     if ( ~isempty(r) )
%         hold on;plot(c,r, '.g');hold off;
%     end
%     [r c] = find(bwIm);
%     if ( ~isempty(r) )
%         hold on;plot(c,r, 'or');hold off;
%     end

    rgnSize = zeros(1,numRegions);
    for i=1:numRegions
        rgnSize(i) = nnz(L==i);
    end
    maxRgnSize = max(rgnSize);
    for i=1:numRegions
        szScale = min([rgnSize(i)*ones(1,numRegions);rgnSize],[],1) ./ maxRgnSize;
%         dg(i,:) = dg(i,:) ./ szScale;
        dg(i,:) = (0.1 * dg(i,:))+  1 ./ szScale;
    end

    dg(dg==0) = 1;
%     mg = mg;
    
    mergeDist = mg ./ dg;
    while ( numRegions > k )
        [minDist minIdx] = min(mergeDist(:));
        if ( isinf(minDist) )
            break;
        end
        
        [rg1 rg2] = ind2sub(size(mergeDist),minIdx);
        bwRg1 = imdilate((L==rg1),se) & bwIm;
        bwRg2 = imdilate((L==rg2),se) & bwIm;
        mergeRg = (bwRg1 & bwRg2) | (L==rg1) | (L==rg2);
        
        L(mergeRg) = rg1;
        
        mergeDist(rg1,rg2) = Inf;
        mergeDist(rg2,rg1) = Inf;
        
        for i=1:numRegions
            if ( i==rg1 )
                continue;
            end
            
            if ( mergeDist(rg1,i) > mergeDist(rg2,i) )
                mergeDist(rg1,i) = mergeDist(rg2,i);
                mergeDist(i,rg1) = mergeDist(rg1,i);
            end
            
            mergeDist(i,rg2) = Inf;
            mergeDist(rg2,i) = Inf;
        end
        
        numRegions = nnz(unique(L(:))>0);
    end
    
    if ( numRegions > k )
        return;
    end
    
    mergedL = cleanupComponents(L);
%     figure();imagesc(L);
%     figure();imagesc(mergedL);
end

function cleanL = cleanupComponents(L)

    cleanL = zeros(size(L));
    newIdx = 1;
    for i=1:max(L(:))
        if ( nnz(L==i) == 0 )
            continue;
        end
        
        bwIm = (L==i);
        cleanL(bwmorph(bwIm,'majority')) = newIdx;
        
        newIdx = newIdx + 1;
    end
end







