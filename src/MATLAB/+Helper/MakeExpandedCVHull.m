function expandPoints = MakeExpandedCVHull(hullPoints, expandRadius)
    expandPoints = [];
    if ( size(hullPoints,1) <= 1 )
        return;
    end
    
    planes = hullPoints(2:end,:) - hullPoints(1:(end-1),:);
    normPlanes = [-planes(:,2) planes(:,1)] ./ repmat(sqrt(sum(planes.^2, 2)), 1, 2);
    
    crossPlanes = (planes(:,1).*[planes(2:end,2);planes(1,2)] - [planes(2:end,1);planes(1,1)].*planes(:,2));
    if ( max(crossPlanes,[],1) > 0 )
        normPlanes = -normPlanes;
    end
    
    normPoints = (normPlanes + [normPlanes(end,:); normPlanes(1:(end-1),:)]) / 2;
    normDots = sum(normPlanes .* [normPlanes(end,:); normPlanes(1:(end-1),:)], 2);
    
    alphas = expandRadius ./ sqrt((1+normDots)/2);
    expandPoints = hullPoints + [[alphas alphas].*normPoints; alphas(1)*normPoints(1,:)];
end
