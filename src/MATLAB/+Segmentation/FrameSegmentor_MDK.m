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