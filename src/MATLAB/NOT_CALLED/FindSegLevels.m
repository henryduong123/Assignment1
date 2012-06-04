function FindSegLevels(bShowProgress)
    global CONSTANTS HashedCells SegLevels
    
    if ( ~exist('bShowProgress', 'var') )
        bShowProgress = 1;
    end
    
    SegLevels = struct('haloLevel',{[]}, 'igLevel',{[]});
    for t=1:length(HashedCells)
        if ( bShowProgress )
            UI.Progressbar((t-1)/length(HashedCells));
        end
        
        fileName = [CONSTANTS.rootImageFolder CONSTANTS.datasetName '_t' Helper.SignificantDigits(t) '.TIF'];
        if exist(fileName,'file')
            [img colrMap] = imread(fileName);
        else
            img=zeros(CONSTANTS.imageSize);
        end
        im = mat2gray(img);
        
        se=strel('square',3);
        gd=imdilate(im,se);
        ge=imerode(im,se);
        ig=gd-ge;

        % rerun part of seg
        SegLevels(t).haloLevel = graythresh(im);
        SegLevels(t).igLevel = graythresh(ig);
    end
    
    if ( bShowProgress )
        UI.Progressbar(1);
    end
end