function  HematoSegmentation()
global CONSTANTS CellHulls FluorData HaveFluor
eccentricity = 1.0;
minVol = 75;
try
    system(['del .\segmentationData\' CONSTANTS.datasetName '*.TIF_seg.txt']);
catch errorMessage
    %fprintf(errorMessage);
end

answr = questdlg('Crop these images?','Crop?','Yes','No','Yes');
if (strcmp(answr,'Yes'))
    croppedFolder = [CONSTANTS.rootImageFolder(1:end-1) '_cropped\.'];
    if (isfield(CONSTANTS, 'rootFluorFolder'))
        croppedFluor = [' ' CONSTANTS.rootFluorFolder '* ' CONSTANTS.rootFluorFolder(1:end-1) '_cropped\.'];
    else
        croppedFluor = '';
    end
    fprintf(1,'Cropping Images...');
    system(['GrayScaleCrop.exe "' CONSTANTS.rootImageFolder '*" ' croppedFolder croppedFluor]);
%    system(['GrayScaleCrop.exe "' CONSTANTS.rootImageFolder '*" ' croppedFolder]);
    CONSTANTS.rootImageFolder = croppedFolder;
    if (isfield(CONSTANTS, 'rootFluorFolder'))
        CONSTANTS.rootFluorFolder = [CONSTANTS.rootFluorFolder(1:end-1) '_cropped\.'];
    end
    im = Helper.LoadIntensityImage(Helper.GetFullImagePath(1));
    Load.AddConstant('imageSize',size(im),1);
end

fprintf(1,'Segmentation...');

system(['start HematoSeg.exe "' CONSTANTS.rootImageFolder '*" ' num2str(CONSTANTS.imageAlpha) ' ' num2str(minVol) ' ' num2str(eccentricity) ' .9 && exit']);

pause(20);

CellHulls = struct(...
    'time',             {},...
    'points',           {},...
    'centerOfMass',     {},...
    'indexPixels',      {},...
    'imagePixels',      {},...
    'deleted',          {},...
    'userEdited',       {});

for i=1:length(dir([CONSTANTS.rootImageFolder '\*.tif']))
    filename = ['.\segmentationData\' Helper.GetImageName(i) '_seg.txt'];
    while (isempty(dir(filename)))
        pause(5);
    end
    file = fopen(filename,'rt');
    
    numHulls = str2double(fgetl(file));
    
    for j=1:numHulls
        id = length(CellHulls)+1;
        CellHulls(id).time = i;
        centerOfMass = fscanf(file,'(%f,%f)\n');
        CellHulls(id).centerOfMass = [centerOfMass(2) centerOfMass(1)];
        numOfpix = str2double(fgetl(file));
        [CellHulls(id).indexPixels, count] = fscanf(file,'%d,');
        CellHulls(id).imagePixels = zeros(count,1);
        CellHulls(id).deleted = 0;
        CellHulls(id).userEdited = 0;
        if(count~=numOfpix)
            error('nope');
        end
    end
    fclose(file);
    
end

for i=1:length(CellHulls)
    [r c] = ind2sub(CONSTANTS.imageSize,CellHulls(i).indexPixels);
    try
        ch = convhull(r,c);
    catch exception
        disp(i);
    end
    CellHulls(i).points = [c(ch) r(ch)];
end

% do fluor segmentation (if provided)

% one of these per frame
FluorData = struct(...
    'greenInd',         {}...
);

HaveFluor = zeros(1,length(dir([CONSTANTS.rootImageFolder '\*.tif'])));

if (isfield(CONSTANTS, 'rootFluorFolder'))
    % rather than hard-wire the interval between fluor images, we'll loop
    % over each possible one from the phase images and see if we have a
    % corresponding fluor image
    for i=1:length(dir([CONSTANTS.rootImageFolder '\*.tif']))
        filename = Helper.GetFullFluorPath(i);
        if (isempty(dir(filename)))
            FluorData(i).greenInd = {};
            continue;
        end
        HaveFluor(i) = 1;
        
        % find all the fluorescence pixels in the image
        fluor = Helper.LoadIntensityImage(filename);
        [bw] = Segmentation.Michel(fluor, [3 3]);
        
        % some early fluor frames are so faint that Michel oversegments
        % them
        w = find(bw);
        wPct = numel(w) / numel(bw(:));
        if wPct < 0.1
            FluorData(i).greenInd = w;
        else
            FluorData(i).greenInd = {};
        end
    end
        
end

fprintf(1,'Done\n');
end

