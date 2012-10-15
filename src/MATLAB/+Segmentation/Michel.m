function [bw] = Michel(im,neighborhood)
    % create a gaussian kernel and blur the image a lot
    h = fspecial('gaussian', 7, 5);
    imfilt = imfilter(im, h, 'symmetric');
    for j=1:50
        imfilt = imfilter(imfilt, h, 'symmetric');
    end

    % create a "high-frequency" image by subtracting
    imhfreq = max((im - imfilt), zeros(size(im)));

    % median filter the high-frequency image
    medim = medfilt2(imhfreq,neighborhood);

    % The rest of this code removes purely zero values then uses an otsu threshold to segment the image
    medimZ = medim(medim>0);

    th = graythresh(medimZ);
    bw = im2bw(medim,th);
    % greenInd = find(imBW);
end
