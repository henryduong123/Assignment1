
function bMayOverlap = RadiusContains(hullIDs, expandRadius, point)
    global CellHulls
    
    radSq = arrayfun(@(x)(max((x.points(:,1)-x.centerOfMass(2)).^2) + max((x.points(:,2)-x.centerOfMass(1)).^2)), CellHulls(hullIDs));
    distSq = arrayfun(@(x)((point(1)-x.centerOfMass(2)).^2 + (point(2)-x.centerOfMass(1)).^2), CellHulls(hullIDs));
    
    bMayOverlap = (distSq <= (radSq + expandRadius^2 + 2*expandRadius*sqrt(radSq)));
    
end
