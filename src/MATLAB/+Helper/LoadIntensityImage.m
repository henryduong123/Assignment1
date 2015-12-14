% imgray = LoadIntensityImage(frame, chan)
% Loads image and calculates "intensity" if it is an rgb image,
% then uses mat2gray to convert to grayscale values on [0,1].

function imgray = LoadIntensityImage(frame, chan)
    global CONSTANTS
    bitrates = [8 12 16];
    
    im = MicroscopeData.Reader(Metadata.GetImageInfo(), frame, chan);
    if ( ndims(im) > 3 )
        error('LEVER tool only supports grayscale images!');
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
    
    % Handle "color" or 3D images by max intensity projection of the color channels to get intensity
    if ( ndims(imgray) == 3 )
        imgray = max(imgray,[],3);
    end
end
