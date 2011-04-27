% Gets original (partial) segmentation from cells which were split and a
% list of the split cells which intersect the original segmentation
% component.
function [newObj mergeHulls] = FindMergedCell(t, centerPt)
    global CONSTANTS CellHulls HashedCells

    fileName = [CONSTANTS.rootImageFolder CONSTANTS.datasetName '_t' SignificantDigits(t) '.TIF'];
    [img colorMap] = imread(fileName);
    img = mat2gray(img);
    
    mergeHulls = [];
    newObj = PartialImageSegment(img, centerPt, 200, CONSTANTS.imageAlpha);
    
    if ( isempty(newObj) )
        return;
    end
    
    chkHulls = [HashedCells{t}.hullID];
    
    bMergeHull = false(length(chkHulls));
    for i=1:length(chkHulls)
        bMergeHull(i) = any(ismember(newObj.indexPixels,CellHulls(chkHulls(i)).indexPixels));
    end
    
    mergeHulls = chkHulls(bMergeHull);
end