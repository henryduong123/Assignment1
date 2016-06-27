
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
