
function [hull feature] = FindNewSegmentation(img, centerPt, subSize, alpha, overlapPoints)
    if ( ~exist('overlapPoints', 'var') )
        overlapPoints = [];
    end
    
    [objs features] = Segmentation.PartialImageSegment(img, centerPt, subSize, alpha);
    
    if ( isempty(overlapPoints) )
        bInHull = Hulls.CheckHullsContainsPoint(centerPt, objs);
    else
        bInHull = false(1,length(objs));
        isectDist = ones(1,length(objs));
        for i=1:length(objs)
            isect = intersect(overlapPoints, objs(i).indPixels);
            isectDist(i) = 1 - (length(isect) / min(length(overlapPoints),length(objs(i).indPixels)));
        end
        [minDist minIdx] = min(isectDist);
        bInHull(minIdx) = (minDist < 1);
    end
    
    hull = objs(find(bInHull,1));
    feature = features(find(bInHull,1));
end
