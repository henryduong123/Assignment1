function bInside = ExpandedHullContains(cvHull, expandRadius, pointList)

    numPoints = size(pointList,1);

    if ( size(cvHull,1) == 1 )
        bInside = (sum((repmat(cvHull,numPoints,1) - pointList).^2, 2) < expandRadius^2);
        return;
    end
    
    expandPoints = Helper.MakeExpandedCVHull(cvHull, expandRadius);
    bInside = inpolygon(pointList(:,1), pointList(:,2), expandPoints(:,1), expandPoints(:,2));
end
