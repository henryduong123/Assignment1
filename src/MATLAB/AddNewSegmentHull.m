function newTrackID = AddNewSegmentHull(clickPt)
    global CONSTANTS CellHulls HashedCells Figures

    fileName = [CONSTANTS.rootImageFolder CONSTANTS.datasetName '_t' SignificantDigits(Figures.time) '.TIF'];
    [img colrMap] = imread(fileName);
    img = mat2gray(img);
    
    newObj = PartialImageSegment(img, clickPt, 200, 1.0);

    newHull = struct('time', [], 'points', [], 'centerOfMass', [], 'indexPixels', [], 'imagePixels', [], 'deleted', 0);
    
    oldTracks = [HashedCells{Figures.time}.trackID];
    
    if ( ~isempty(newObj) )
        newObj = makeNonOverlapping(newObj, Figures.time, clickPt);
    end
    
    if ( isempty(newObj) )
        % Add a point hull since we couldn't find a segmentation containing the click
        newHull.time = Figures.time;
        newHull.points = round(clickPt);
        newHull.centerOfMass =  [clickPt(2) clickPt(1)];
        newHull.indexPixels = sub2ind(size(img), newHull.points(2), newHull.points(1));
        newHull.imagePixels = img(newHull.indexPixels);
    else
        newHull.time = Figures.time;
        newHull.points = newObj.points;
        newHull.centerOfMass = newObj.centerOfMass;
        newHull.indexPixels = newObj.indexPixels;
        newHull.imagePixels = newObj.imagePixels;
    end

    newHullID = length(CellHulls)+1;
    CellHulls(newHullID) = newHull;
    newFamilyIDs = NewCellFamily(newHullID, newHull.time);
    
    newTrackID = TrackSplitHulls(newHullID, oldTracks, newHull.centerOfMass);
    
%     newTrackID = [CellFamilies(newFamilyIDs).rootTrackID];
end

%TODO: Maybe handle convex hull intersection instead of interior points as
%the current method still allows considerable hull overlap in some cases.
function newobj = makeNonOverlapping(obj, t, clickPt)
    global CONSTANTS CellHulls HashedCells
    
    newobj = [];
    
    ccidxs = vertcat(CellHulls([HashedCells{t}.hullID]).indexPixels);
    pix = obj.indexPixels;
    
    bPickPix = ~ismember(pix, ccidxs);
    
    if ( all(bPickPix) )
        newobj = obj;
        return;
    end
    
    bwimg = zeros(CONSTANTS.imageSize);
    bwimg(pix(bPickPix)) = 1;
    
    CC = bwconncomp(bwimg,8);
    if ( CC.NumObjects < 1 )
        newobj = [];
        return;
    end
    
    for i=1:CC.NumObjects
        [r c]=ind2sub(size(bwimg),CC.PixelIdxList{i});
        try
            ch = convhull(r,c);
        catch errmsg
            continue;
        end
        
        if ( inpolygon(clickPt(1), clickPt(2), c(ch), r(ch)) )
            bCCPix = ismember(pix, CC.PixelIdxList{i});
            
            newobj.indexPixels = CC.PixelIdxList{i};
            newobj.imagePixels = obj.imagePixels(bCCPix);
            
            newobj.points = [c(ch) r(ch)];
            newobj.centerOfMass = mean([r c]);
            
            break;
        end
    end
end

