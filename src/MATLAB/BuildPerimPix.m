function [perimPix, perimr, perimc] = BuildPerimPix(polyPix, imSize)
    [r c] = ind2sub(imSize, polyPix);
    
    xlims = Clamp([min(c) max(c)], 1, imSize(2));
    ylims = Clamp([min(r) max(r)], 1, imSize(1));
    
    locr = r - ylims(1) + 1;
    locc = c - xlims(1) + 1;
    
    locsz = [ylims(2)-ylims(1) xlims(2)-xlims(1)]+1;
    locind = sub2ind(locsz, locr, locc);
    
    bwim = false(locsz);
    bwim(locind) = 1;
    
    B = bwboundaries(bwim, 4, 'noholes');
    perimr = [];
    perimc = [];
    for i=1:length(B)
        perimr = [perimr; B{i}(:,1) + ylims(1) - 1];
        perimc = [perimc; B{i}(:,2) + xlims(1) - 1];
    end
    
    perimPix = unique(sub2ind(imSize, perimr, perimc));
end

function x_clamped = Clamp(x, minval, maxval)
    x_clamped = max(cat(3,x,minval*ones(size(x))),[],3);
    x_clamped = min(cat(3,x_clamped,maxval*ones(size(x))),[],3);
end