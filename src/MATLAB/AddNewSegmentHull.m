function newTrackID = AddNewSegmentHull(clickPt)
    global CONSTANTS CellHulls HashedCells Figures

    fileName = [CONSTANTS.rootImageFolder CONSTANTS.datasetName '_t' num2str(Figures.time,'%03d') '.TIF'];
    [img colorMap] = imread(fileName);
    img = mat2gray(img);
    
    newObj = PartialImageSegment(img, clickPt, 200, 1.0);

    newHull = struct('time', [], 'points', [], 'centerOfMass', [], 'indexPixels', [], 'imagePixels', [], 'deleted', 0);
    
    oldTracks = [HashedCells{Figures.time}.trackID];
    
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