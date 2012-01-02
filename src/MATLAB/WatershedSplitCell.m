function [newHulls newFeatures] = WatershedSplitCell(cell, cellFeat, k)
global CONSTANTS

newHulls = [];
newFeatures = [];

[r c] = ind2sub(CONSTANTS.imageSize,cell.indexPixels);

xlims = Clamp([min(c)-5 max(c)+5], 1, CONSTANTS.imageSize(2));
ylims = Clamp([min(r)-5 max(r)+5], 1, CONSTANTS.imageSize(1));

locr = r - ylims(1) + 1;
locc = c - xlims(1) + 1;

locsz = [ylims(2)-ylims(1) xlims(2)-xlims(1)]+1;

locind = sub2ind(locsz, locr, locc);

locbw = false(locsz);
locbw(locind) = 1;

D = -bwdist(~locbw);

%     h = prctile(D(locbw),5) - min(D(locbw));
%     D = imhmin(D, h);

D(~locbw) = -Inf;
L = watershed(D);

%     figure;imagesc(L);colormap(gray);hold on;

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
end

[dump,ptidx] = min(locdist,[],2);

%     [bwDark bwig bwHalo] = SegDarkCenters(cell.time, CONSTANTS.imageAlpha);
center = [cell.centerOfMass(2) cell.centerOfMass(1)];
[bwDark bwig bwHalo] = PartialSegDarkCenters(center, cell.time, CONSTANTS.imageAlpha);

cmap = hsv(k);
for i=1:k
    pts = [locr(ptidx==i) locc(ptidx==i)];
    %         plot(pts(:,2),pts(:,1), '.', 'Color',cmap(i,:));
    
    hullr = r(ptidx==i);
    hullc = c(ptidx==i);
    
    com = mean([hullr hullc],1);
    ch = convhull(hullr, hullc);
    pts = [hullc(ch) hullr(ch)];
    idxPix = cell.indexPixels(ptidx==i);
    imPix = cell.imagePixels(ptidx==i);
    
    nh = struct('time',{cell.time}, 'points',{pts}, 'centerOfMass',{com}, 'indexPixels',{idxPix}, 'imagePixels',{imPix}, 'deleted',{0}, 'userEdited',{0});
    newHulls = [newHulls nh];
end

% Calculate new features if passed in feature structure is valids
if ( isempty(cellFeat) )
    return;
end

[polyr polyc] = ind2sub(CONSTANTS.imageSize,cellFeat.polyPix);
locpolyr = polyr - ylims(1) + 1;
locpolyc = polyc - xlims(1) + 1;

polydist = Inf*ones(length((locpolyr)),k);
for i=1:k
    polydist(:,i) = ((locpolyr-centers(i,1)).^2 + (locpolyc-centers(i,2)).^2);
end

[dump,polyidx] = min(polydist,[],2);

for i=1:k
    polypts = [locpolyr(polyidx==i) locpolyc(polyidx==i)];
    %         bLocal = (polypts(:,1)>0 & polypts(:,2)>0);
    %         polypts = polypts(bLocal,:);
    %         plot(polypts(:,2),polypts(:,1), 'o', 'Color',cmap(i,:));
    
    nf = struct('darkRatio',{0}, 'haloRatio',{0}, 'igRatio',{0}, 'darkIntRatio',{0}, 'brightInterior',{0}, 'polyPix',{[]}, 'perimPix',{[]}, 'igPix',{[]}, 'haloPix',{[]});
    
    polyPix = cellFeat.polyPix(polyidx==i);
    perimPix = BuildPerimPix(polyPix, CONSTANTS.imageSize);
    
    %             [tr tc] = ind2sub(CONSTANTS.imageSize, perimPix);
    %             loctr = tr - ylims(1);
    %             loctc = tc - xlims(1);
    
    %             bLocal = (loctr>0 & loctc>0);
    %             loctr = loctr(bLocal);
    %             loctc = loctc(bLocal);
    
    %             plot(loctc,loctr, '.', 'Color',[0 1 0])
    
    igRat = nnz(bwig(perimPix)) / length(perimPix);
    HaloRat = nnz(bwHalo(perimPix)) / length(perimPix);
    
    %             bwDarkInterior = bwDarkCenters(polyPix);
    %             DarkRat = nnz(bwDarkInterior) / length(polyPix);
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
