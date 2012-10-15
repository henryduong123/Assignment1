function [objs features levels] = WehiFrameSegmentor(im, t, imageAlpha)
    objs = [];
    features = [];
    levels = struct('haloLevel',{0}, 'igLevel',{0});
    
    % get the fluorescence image
    fname = Helper.GetFullFluorPath(t);
    if(isempty(dir(fname)))
        return;
    end
    
    fluor = Helper.LoadIntensityImage(fname);
    [bw] = Segmentation.Michel(fluor, [3 3]);
    [r c] = find(bw);
    [L num] = bwlabel(bw);
    for n=1:num
        [r c] = find(L==n);
        pix = find(L == n);
        
        if length(r) < 15
            continue
        end
        ch = convhull(c, r);
        
        no = [];
        no.t = t;
        no.points = [c(ch),r(ch)];
        no.indPixels = pix;
        no.imPixels = im(pix);
        objs = [objs no];
        nf = [];
        nf.id=length(objs);
        features = [features nf];
    end
end