function newTrackID = AddNewSegmentHull(clickPt)
    global CONSTANTS CellHulls CellFamilies Figures

    fileName = [CONSTANTS.rootImageFolder CONSTANTS.datasetName '_t' num2str(Figures.time,'%03d') '.TIF'];
    [img colrMap] = imread(fileName);
    img = mat2gray(img);
    
    newObj = PartialImageSegment(img, clickPt, 200, 1.0);

    newHull = struct('time', [], 'points', [], 'centerOfMass', [], 'indexPixels', [], 'deleted', 0);
    
    if ( isempty(newObj) )
        % Add a point hull since we couldn't find a segmentation containing the click
        newHull.time = Figures.time;
        newHull.points = round(clickPt);
        newHull.centerOfMass =  [clickPt(2) clickPt(1)];
        newHull.indexPixels = sub2ind(size(img), newHull.points(2), newHull.points(1));
    else
        newHull.time = Figures.time;
        newHull.points = newObj.points;
        newHull.centerOfMass = newObj.centerOfMass;
        newHull.indexPixels = newObj.indexPixels;
    end

    CellHulls(end+1) = newHull;
    newFamilyIDs = NewCellFamily(length(CellHulls), newHull.time);
    
    newTrackID = [CellFamilies(newFamilyIDs).rootTrackID];
end