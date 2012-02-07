function assignIdx = AssignPolyPix(polyPix, connComps, imSize)
    [r c] = ind2sub(imSize, polyPix);
    
    xlims = Clamp([min(c) max(c)], 1, imSize(2));
    ylims = Clamp([min(r) max(r)], 1, imSize(1));
    
    rCC = cell(1,length(connComps));
    cCC = cell(1,length(connComps));
    for i=1:length(connComps)
        [rCC{i} cCC{i}] = ind2sub(imSize, connComps{i});
        
        xlims = Clamp([min([xlims(1); cCC{i}]) max([xlims(2); cCC{i}])], 1, imSize(2));
        ylims = Clamp([min([ylims(1); rCC{i}]) max([ylims(2); rCC{i}])], 1, imSize(1));
    end
    
    locsz = [ylims(2)-ylims(1) xlims(2)-xlims(1)]+1;
    
    lblim = zeros(locsz);
    bwim = false(locsz);
    for i=1:length(connComps)
        locr = rCC{i} - ylims(1) + 1;
        locc = cCC{i} - xlims(1) + 1;
        
        locind = sub2ind(locsz, locr,locc);
        
        bwim(locind) = 1;
        lblim(locind) = i;
    end
    
    locr = r - ylims(1) + 1;
    locc = c - xlims(1) + 1;
    
    locind = sub2ind(locsz, locr,locc);
    
    [d,L] = bwdist(bwim);
    assignIdx = lblim(L(locind));
    
%     cmap = hsv(length(connComps));
%     figure;imagesc(bwim);colormap(gray);hold on;
%     for i=1:length(connComps)
%         tr = locr(assignIdx == i);
%         tc = locc(assignIdx == i);
%         plot(tc, tr, '.', 'Color',cmap(i,:));
%     end
end