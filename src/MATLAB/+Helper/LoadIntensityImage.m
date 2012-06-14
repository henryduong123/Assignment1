% imgray = LoadIntensityImage(filename)
% Loads image and calculates "intensity" if it is an rgb image,
% then uses mat2gray to convert to grayscale values on [0,1].

function imgray = LoadIntensityImage(filename)
    [im map]=imread(filename);
    
    if ( ndims(im) > 3 )
        error('LEVER tool only supports grayscale images, please select single channel tiff images.');
    end
    
    % Handle "color" images by averaging the color channels to get
    % intensity (should all be the same for all channels)
    if ( ndims(im) == 3 )
        im = mean(im,3);
    end
    
    imgray = mat2gray(im);
end