
function hull = FindNewSegmentation(chanImg, centerPt, subSize, bSearchParams, overlapPoints, time)
    global CONSTANTS
    
    typeParams = Load.GetCellTypeParameters(CONSTANTS.cellType);
    
    resegRoutines = typeParams.resegRoutines;
    for i=1:length(resegRoutines)
        segFunc = resegRoutines(i).func;
        
        % Search 5 levels in the range of each entry if we are searching.
        chkParams = resegRoutines(i).params;
        paramList = recBuildParams([], chkParams);
        
        if ( isempty(paramList) )
            chkHulls = Segmentation.PartialImageSegment(chanImg, centerPt, subSize, segFunc, paramArgs);
            hull = validIntersectHull(chkHulls, centerPt, overlapPoints);
        end
        
        for j=1:size(paramList)
            paramArgs = mat2cell(paramList(j,:),1,1);
            chkHulls = Segmentation.PartialImageSegment(chanImg, centerPt, subSize, segFunc, paramArgs);

            hull = validIntersectHull(chkHulls, centerPt, overlapPoints);
            
            if ( ~isempty(hull) )
                break;
            end
        end
        
        if ( isempty(hull) )
            continue;
        end
        
        if ( ~isfield(hull,'tag') || isempty(hull.tag) )
            hull.tag = char(segFunc);
        else
            hull.tag = [char(resegRoutines(i).func) ':' hull.tag];
        end
    end
end

function paramList = recBuildParams(inList, chkParams)
    paramList = inList;
    
    if ( isempty(chkParams) )
        return;
    end
    
    curParam = chkParams{1};
    
    paramRange = curParam.range;
    if ( isempty(paramRange) )
        paramRange = [curParam.default curParam.default 1];
    end
    
    paramSet = linspace(paramRange(1), paramRange(2), paramRange(3));
    [X Y] = meshgrid(1:size(paramList,1), length(paramSet));
    
    paramList = [paramList(X(:)) paramSet(Y(:))];
    paramList = recBuildParams(paramList, chkParams(2:end));
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
