function coord = IndexToCoord(arraySize, arrayIdx)
    coord = zeros(length(arrayIdx),length(arraySize));
    
    linSize = [1 cumprod(arraySize)];
    partialIdx = arrayIdx;
    for i = length(arraySize):-1:1
        r = rem(partialIdx-1, linSize(i)) + 1;
        q = floor((partialIdx-r) / linSize(i)) + 1;
        
        coord(:,i) = q;
        partialIdx = r;
    end
end
