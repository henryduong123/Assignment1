% FindSegLevels(bShowProgress)
% Create segmentation (alpha) levels per image frame.

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
        
        fileName = [CONSTANTS.rootImageFolder CONSTANTS.datasetName '_t' Helper.GetDigitString(t) '.TIF'];
        if exist(fileName,'file')
            im = Helper.LoadIntensityImage(fileName);
        else
            im = zeros(CONSTANTS.imageSize);
        end
        
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