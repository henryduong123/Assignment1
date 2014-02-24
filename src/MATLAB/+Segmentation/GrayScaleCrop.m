function  GrayScaleCrop()
global CONSTANTS

cropRegion = Segmentation.FindCropRegion(Helper.GetFullImagePath(1));
outDir = CropFolder(CONSTANTS.rootImageFolder, cropRegion);
CONSTANTS.rootImageFolder = [outDir '\'];

if (isfield(CONSTANTS, 'rootFluorFolder'))
    outDir = CropFolder(CONSTANTS.rootFluorFolder, cropRegion);
    CONSTANTS.rootFluorFolder = [outDir '\'];
end

end

function [outDir] = CropFolder( inDir, region )
inDir = inDir(1:end-1);
outDir = [inDir '_cropped'];
if exist(outDir, 'dir') ~= 7
    mkdir(outDir);
end

flist = dir([ inDir '\*.tif']);
parfor i=1:length(flist)
    inName = [inDir '\' flist(i).name];
    outName = [outDir '\' flist(i).name];
    
    im = imread(inName);
    imwrite(im( region(1):region(3), region(2):region(4) ), outName);
end
end
