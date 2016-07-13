% imgray = LoadIntensityImage(frame, chan)
% Loads image and calculates "intensity" if it is an rgb image,
% then uses mat2gray to convert to grayscale values on [0,1].

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


function imgray = LoadIntensityImage(frame, chan)
    global CONSTANTS
    bitrates = [8 12 16];
    
    im = MicroscopeData.Reader('imageData',Metadata.GetImageInfo(), 'chanList',chan, 'timeRange',[frame frame], 'prompt',false);
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
