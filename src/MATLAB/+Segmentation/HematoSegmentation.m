function  HematoSegmentation()
global CONSTANTS CellHulls
eccentricity = 1.0;
minVol = 200;
try
    system(['del .\segmentationData\' CONSTANTS.datasetName '*.TIF_seg.txt']);
catch errorMessage
    %fprintf(errorMessage);
end

answr = questdlg('Crop these images?','Crop?','Yes','No','Yes');
if (strcmp(answr,'Yes'))
    croppedFolder = [CONSTANTS.rootImageFolder(1:end-1) '_cropped\.'];
    fprintf(1,'Cropping Images...');
    system(['GrayScaleCrop.exe "' CONSTANTS.rootImageFolder '*" ' croppedFolder]);
    CONSTANTS.rootImageFolder = croppedFolder;
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
    ch = convhull(r,c);
    CellHulls(i).points = [c(ch) r(ch)];
end

fprintf(1,'Done\n');
end

