function [mergeObj, deleteCells] = CreateMergedCell(mergeCells)
    global CONSTANTS CellHulls
    
    mergeObj = [];
    deleteCells = [];
    
    ccM = calcConnDistM(mergeCells);
    [S,C] = graphconncomp(sparse(ccM <= 5));
    
    largestC = 0;
    szC = 0;
    for i=1:S
        if ( nnz(C==i) > szC )
            largestC = i;
            szC = nnz(C==i);
        end
    end
    
    if ( szC > 1 )
        deleteCells = mergeCells(C == largestC);
        
        mergeObj.time = CellHulls(deleteCells(1)).time;
        mergeObj.indexPixels = vertcat(CellHulls(deleteCells).indexPixels);
        mergeObj.imagePixels = vertcat(CellHulls(deleteCells).imagePixels);
        
        [r c] = ind2sub(CONSTANTS.imageSize, mergeObj.indexPixels);
        try
            ch = convhull(r,c);
        catch err
        end
        
        mergeObj.points = [c(ch) r(ch)];
        mergeObj.centerOfMass = mean([r c]);
    end
end

function ccM = calcConnDistM(cells)
    global CONSTANTS CellHulls
    
    ccM = zeros(length(cells), length(cells));
    for i=1:length(cells)
        for j=1:length(cells)
            if ( i == j )
                ccM(i,j) = Inf;
                continue;
            end
            
            [ri ci] = ind2sub(CONSTANTS.imageSize, CellHulls(cells(i)).indexPixels);
            [rj cj] = ind2sub(CONSTANTS.imageSize, CellHulls(cells(j)).indexPixels);
            
            [idxi, idxj] = ndgrid(1:length(ri), 1:length(rj));
            
            distsq = ((ri(idxi)-rj(idxj)).^2 + (ci(idxi)-cj(idxj)).^2);
            ccM(i,j) = sqrt(min(distsq(:)));
        end
    end
end