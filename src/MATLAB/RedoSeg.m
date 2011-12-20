function RedoSeg(imageAlpha)
    global CONSTANTS CellHulls CellFeatures
    
%     CellHulls = [];
%     CellFeatures = [];

    fileList = dir([CONSTANTS.rootImageFolder CONSTANTS.datasetName '*.tif']);
    numberOfImages = length(fileList);

    NewHulls = [];
    NewFeatures = [];
    
    for t=1:numberOfImages
        fileName = [CONSTANTS.rootImageFolder CONSTANTS.datasetName '_t' SignificantDigits(t) '.TIF'];
        if ( isempty(dir(fileName)) )
            continue;
        end
        
        [im map]=imread(fileName);
    
        [frmObjs frmFeatures] = FrameSegmentor(im, t, imageAlpha);
        NewFeatures = [NewFeatures frmFeatures];
        
        frmHulls = struct('time',{}, 'points',{}, 'centerOfMass',{}, 'indexPixels',{}, 'imagePixels',{}, 'deleted',{}, 'userEdited',{});
        for i=1:length(frmObjs)
            [r c] = ind2sub(size(im), frmObjs(i).indPixels);
            frmHulls(i).time = t;
            frmHulls(i).points = frmObjs(i).pts;
            frmHulls(i).centerOfMass = mean([r c],1);
            frmHulls(i).indexPixels = frmObjs(i).indPixels;
            frmHulls(i).imagePixels = frmObjs(i).imPixels;
            frmHulls(i).deleted = 0;
            frmHulls(i).userEdited = 0;
        end
        
        NewHulls = [NewHulls frmHulls];
    end
    
    CellHulls = NewHulls;
    CellFeatures = NewFeatures;
end