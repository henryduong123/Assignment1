
function hull = FindNewSegmentation(chanImg, centerPt, subSize, bSearchParams, overlapPoints, time)
    global CONSTANTS
    
    typeParams = Load.GetCellTypeParameters(CONSTANTS.cellType);
    
    resegRoutines = typeParams.resegRoutines;
    for i=1:length(resegRoutines)
        segFunc = resegRoutines(i).func;
        
        % Search 5 levels in the range of each entry if we are searching.
        chkParams = resegRoutines(i).params;
        
        paramSpace = {};
        for j=1:length(chkParams)
            paramRange = chkParams(j).range;
            if ( isempty(paramRange) )
                paramSpace{j} = chkParams(j).default;
            end
            
            if ( bSearchParams )
                paramSpace{j} = linspace(paramRange(1), paramRange(2), paramRange(3));
            else
                paramSpace{j} = paramRange(1);
            end
        end
        
        paramGrid = cell(1,length(chkParams));
        if ( ~isempty(chkParams) )
            [paramGrid{:}] = ndgrid(paramSpace{:});
        end
        
        for j=1:numel(paramGrid{1})
            paramArgs = cellfun(@(x)(x(j)), paramGrid, 'UniformOutput',0);
            chkHulls = Segmentation.PartialImageSegment(chanImg, centerPt, subSize, time, segFunc, paramArgs);

            hull = validIntersectHull(chkHulls, centerPt, overlapPoints);
            if ( ~isempty(hull) )
                if ( ~isfield(hull,'tag') || isempty(hull.tag) )
                    hull.tag = char(segFunc);
                else
                    hull.tag = [char(resegRoutines(i).func) ':' hull.tag];
                end

                return;
            end
        end
        
    end
end

function hull = validIntersectHull(chkHulls, centerPt, overlapPoints)
    if ( isempty(overlapPoints) )
        bInHull = Hulls.CheckHullsContainsPoint(centerPt, chkHulls);
    else
        bInHull = false(1,length(chkHulls));
        isectDist = ones(1,length(chkHulls));
        
        for i=1:length(chkHulls)
            isect = intersect(overlapPoints, chkHulls(i).indexPixels);
            isectDist(i) = 1 - (length(isect) / min(length(overlapPoints),length(chkHulls(i).indexPixels)));
        end
        
        [minDist minIdx] = min(isectDist);
        bInHull(minIdx) = (minDist < 1);
    end
    
    hull = chkHulls(find(bInHull,1));
end
