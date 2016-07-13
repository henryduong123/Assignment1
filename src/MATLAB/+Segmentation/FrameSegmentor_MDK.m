% FrameSegmentor_test - This is a frame segmentor example for identifying
% cell texture in brightfield imaging and splitting into components using a
% number of nuclear fluorescent channel markers.
% 
% hulls = FrameSegmentor(chanIm, primaryChan, t, seRadius)
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
%   seRadius - Radius of a neaighborhood element for the brightfield
%   texture filter. Increasing the radius will generally connect
%   segmentations.
% 
%
% OUTPUTS:
%   hulls - The hulls output should be a structure array with one entry per
%   segmentation result.
%   At a minimum, each hull must contain an 'indexPixels' field, a list of
%   linear indices representing the interior pixels of segmentation results.
%   For example, the PixelIdxList result from a call to regionprops could
%   be used to fill the hulls indexPixels field.
% 

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
%     Copyright 2016 Drexel University
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

function hulls = FrameSegmentor_MDK(chanIm, primaryChan, t, imageAlpha)
    hulls = [];
    
    otherChan = setdiff(1:length(chanIm),primaryChan);
    % Brightfield texture segmentation
    im = chanIm{primaryChan};
    im=mat2gray(im);
    thresh=imageAlpha*multithresh(im,3);
    q=imquantize(im,thresh);
    bw=0*im;
    bw(q==1)=1;
    bw=imclose(bw,strel('disk',4));
    
    [L num]=bwlabel(bw);
    for n=1:num
        [r c]=find(L==n);
        idx=find(L==n);
        if length(r)<50
            continue
        end
        if length(r)>5000
            continue;
        end
        chIdx = Helper.ConvexHull(c,r);
        if ( isempty(chIdx) )
            continue;
        end
        nh = struct('indexPixels',idx, 'points',{[c(chIdx), r(chIdx)]});
        hulls = [hulls nh];
    end