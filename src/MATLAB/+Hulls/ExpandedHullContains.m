function bInside = ExpandedHullContains(cvHull, expandRadius, pointList)

    numPoints = size(pointList,1);

    if ( size(cvHull,1) == 1 )
        bInside = (sum((repmat(cvHull,numPoints,1) - pointList).^2, 2) < expandRadius^2);
        return;
    end
    
    planes = cvHull(2:end,:) - cvHull(1:(end-1),:);
    normPlanes = [-planes(:,2) planes(:,1)] ./ repmat(sqrt(sum(planes.^2, 2)), 1, 2);
    
    if ( det([planes(1,:); planes(2,:)]) < 0 )
        normPlanes = -normPlanes;
    end
    
    normPoints = normPlanes + [normPlanes(end,:); normPlanes(1:(end-1),:)];
    normDots = sum(normPlanes .* [normPlanes(end,:); normPlanes(1:(end-1),:)], 2);
    
    alphas = expandRadius ./ (1+normDots);
    expandPoints = cvHull + [[alphas alphas].*normPoints; alphas(1)*normPoints(1,:)];
    
    bInside = inpolygon(pointList(:,1), pointList(:,2), expandPoints(:,1), expandPoints(:,2));
end