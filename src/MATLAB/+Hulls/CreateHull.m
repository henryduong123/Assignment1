function newHull = CreateHull(rcImageDims, indexPixels, time, userEdited, tag)
    global CellHulls
    
    if ( ~exist('time','var') )
        time = 1;
    end
    
    if ( ~exist('userEdited','var') )
        userEdited = false;
    end
    
    if ( ~exist('tag','var') )
        tag = '';
    end
    
    newHull = [];
    if ( ~isempty(CellHulls) )
        newHull = Helper.MakeEmptyStruct(CellHulls);
    end
    
    rcCoords = Helper.IndexToCoord(rcImageDims, indexPixels);
    xyCoords = Helper.SwapXY_RC(rcCoords);
    
    newHull.indexPixels = indexPixels;
    newHull.centerOfMass = mean(rcCoords,1);
        
    chIdx = Helper.ConvexHull(xyCoords(:,1), xyCoords(:,2));
    if ( isempty(chIdx) )
        newHull = [];
        return;
    end

    newHull.points = xyCoords(chIdx,:);
    
    newHull.time = time;
    newHull.userEdited = (userEdited > 0);
    newHull.tag = tag;
end
