function A = findAffineTransform(lastPoints, stainPoints)
    hLastPoints = [lastPoints ones(size(lastPoints,1),1)];
    hStainPoints = [stainPoints ones(size(stainPoints,1),1)];
    
    A = pinv(hLastPoints)*hStainPoints;
end
