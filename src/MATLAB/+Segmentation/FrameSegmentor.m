% FrameSegmentor - This is a frame segmentor stub example documenting the
% protocol that all segmentation algorithms must follow to be integrated
% directly into the LEVER tool.
% 
% All FrameSegmentor algorithms must be registered in Load.GetSupportedCellTypes
% in order to be recognized by LEVER. 
% 
% hulls = FrameSegmentor(chanIm, primaryChan, t, ...)
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
%   ... - Additional segmentation-specific parameters are supported. See
%   Load.GetSupportedCellTypes and Segmentation.FrameSegmentor_Adult for
%   further details on segmentation-specific parameters.
%
% OUTPUTS:
%   hulls - The hulls output should be a structure array with one entry per
%   segmentation result.
%   At a minimum, each hull must contain an 'indexPixels' field, a list of
%   linear indices representing the interior pixels of segmentation results.
%   For example, the PixelIdxList result from a call to regionprops could
%   be used to fill the hulls indexPixels field.
% 
%   See also Load.GetSupportedCellTypes, Segmentation.FrameSegmentor_Adult, REGIONPROPS.
% 
function hulls = FrameSegmentor(chanIm, primaryChan, t, vararagin)
    hulls = [];
    
    %% Run a simplistic global thresholding to find segmentation results using the Otsu's algorithm.
    im = chanIm{primaryChan};
    
    threshold = graythresh(im);
    
    % Make sure threshold isn't too high or too low (causes errors in im2bw).
    threshold = min(max(threshold, 0.05), 0.95);
    
    bwIm = im2bw(im, threshold);
    
    % Remove very small or large components
    ccProps = regionprops(bwIm, 'Area','PixelIdxList');
    for i=1:length(ccProps)
        if ( ccProps(i).Area < 20 )
            continue;
        end
        
        if ( ccProps(i).Area > 0.05*numel(im) )
            continue;
        end
        
        nh = struct('indexPixels',{ccProps.PixelIdxList});
        hulls = [hulls nh];
    end
end
