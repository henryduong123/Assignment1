global CONSTANTS FluorData HaveFluor

% do fluor segmentation (if provided)

% one of these per frame
FluorData = struct(...
    'greenInd',         []...
);

HaveFluor = zeros(1,length(dir([CONSTANTS.rootImageFolder '\*.tif'])));

if (isfield(CONSTANTS, 'rootFluorFolder'))
    % rather than hard-wire the interval between fluor images, we'll loop
    % over each possible one from the phase images and see if we have a
    % corresponding fluor image
    for i=1:length(dir([CONSTANTS.rootImageFolder '\*.tif']))
        filename = Helper.GetFullFluorPath(i);
        if (isempty(dir(filename)))
            FluorData(i).greenInd = [];
            continue;
        end
        HaveFluor(i) = 1;
        
        % find all the fluorescence pixels in the image
        fluor = Helper.LoadIntensityImage(filename);
        [bw] = Segmentation.Michel(fluor, [3 3]);
        w = find(bw);
        wPct = numel(w) / numel(bw(:));
        if wPct < 0.1
            FluorData(i).greenInd = w;
        else
            FluorData(i).greenInd = [];
        end
    end
        
end