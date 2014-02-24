function [ region ] = findCropRegion( fname )
    alpha = 0.5;
    border = 5;
    
    im = imread(fname);
    im = mat2gray(im);
    th = graythresh(im);
    bw = im2bw(im, th * alpha);
    % imagesc(bw), colormap(gray);
    
    CC = bwconncomp(bw);
    numPixels = cellfun(@numel,CC.PixelIdxList);
    [biggest idx] = max(numPixels);
    [r c] = ind2sub(size(bw), CC.PixelIdxList{idx});
    minR = min(r);
    minC = min(c);
    maxR = max(r);
    maxC = max(c);
    
    region = [(minR + border) (minC + border) (maxR - border) (maxC - border)];
end

