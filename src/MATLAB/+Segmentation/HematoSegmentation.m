function  HematoSegmentation(imageAlpha)
global CONSTANTS CellHulls

system(['del .\segmentationData\' CONSTANTS.datasetName '*.TIF_seg.txt']);
system(['start HematoSeg.exe ' CONSTANTS.rootImageFolder '\* ' num2str(imageAlpha) '&& exit']);

pause(5);
CellHulls = struct(...
    'time',             {},...
    'points',           {},...
    'centerOfMass',     {},...
    'indexPixels',      {},...
    'imagePixels',      {},...
    'deleted',          {},...
    'userEdited',       {});

for i=1:length(dir([CONSTANTS.rootImageFolder '\*.tif']))
    filename = ['.\segmentationData\' CONSTANTS.datasetName '_t' Helper.GetDigitString(i) '.TIF_seg.txt'];
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

im = imread([CONSTANTS.rootImageFolder '\' CONSTANTS.datasetName '_t' Helper.GetDigitString(1) '.TIF']);
CONSTANTS.imageSize = size(im);

for i=1:length(CellHulls)
    [r c] = ind2sub(CONSTANTS.imageSize,CellHulls(i).indexPixels);
    ch = convhull(r,c);
    CellHulls(i).points = [c(ch) r(ch)];
end

end

