function newTrackID = AddSegmentHull(clickPt, time)
    global CONSTANTS CellHulls

    filename = Helper.GetFullImagePath(time);
    img = Helper.LoadIntensityImage(filename);
 
    if strcmp(CONSTANTS.cellType, 'Hemato')
        subSize = 100;
    else
        subSize = 200;
    end
    
    [newObj newFeat] = Segmentation.FindNewSegmentation(img, clickPt, subSize, 1.0, [], time);
    
    if ( ~isempty(newObj) )
        newObj = Segmentation.ForceDisjointSeg(newObj, time, clickPt);
    end
    
    newHull = Helper.MakeEmptyStruct(CellHulls);
    newHull.userEdited = true;
    
    if ( isempty(newObj) )
        % Add a point hull since we couldn't find a segmentation containing the click
        newHull.time = time;
        newHull.points = round(clickPt);
        newHull.centerOfMass =  [clickPt(2) clickPt(1)];
        newHull.indexPixels = sub2ind(size(img), newHull.points(2), newHull.points(1));
        newHull.imagePixels = img(newHull.indexPixels);
    else
        newHull.time = time;
        newHull.points = newObj.points;
        [r c] = ind2sub(CONSTANTS.imageSize, newObj.indPixels);
        newHull.centerOfMass = mean([r c]);
        newHull.indexPixels = newObj.indPixels;
        newHull.imagePixels = newObj.imPixels;
    end
    
    newHullID = Hulls.SetHullEntries(0, newHull);
    newTrackID = Hulls.GetTrackID(newHullID);
    
    Backtracker.UpdateHullTracking(newHullID);
end
