% imgray = LoadIntensityImage(filename)
% Loads image and calculates "intensity" if it is an rgb image,
% then uses mat2gray to convert to grayscale values on [0,1].

function imgray = LoadIntensityImage(filename)
    global CONSTANTS
    bitrates = [8 12 16];
    
    [im map]=imread(filename);
    
    if ( ndims(im) > 3 )
        error('LEVER tool only supports grayscale images, please select single channel tiff images.');
    end
    
    if ( ~isfield(CONSTANTS,'bitrate') )
        CONSTANTS.bitrate = 8;
    end
    
    if ( isa(im, 'uint8') )
        imgray = mat2gray(im, [0 255]);
    elseif ( isa(im, 'uint16') )
        imMax = max(im(:));
        for i=1:length(bitrates)
            if ( imMax >= 2^bitrates(i) )
                continue;
            end
            
            CONSTANTS.bitrate = max(CONSTANTS.bitrate,bitrates(i));
            imgray = mat2gray(im, [0 2^CONSTANTS.bitrate-1]);
            break;
        end
    else
        imgray = mat2gray(im);
    end
    
    % Handle "color" images by averaging the color channels to get
    % intensity (should all be the same for all channels)
    if ( ndims(im) == 3 )
        im = mean(im,3);
    end
end
