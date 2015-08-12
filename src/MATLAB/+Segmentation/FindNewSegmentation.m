
function hull = FindNewSegmentation(chanImg, centerPt, subSize, bSearchParams, overlapPoints, time)
    global CONSTANTS
    
    typeParams = Load.GetCellTypeParameters(CONSTANTS.cellType);
    
    resegRoutines = typeParams.resegRoutines;
    for i=1:length(resegRoutines)
        segFunc = resegRoutines(i).func;
        
        % Search 5 levels in the range of each entry if we are searching.
        chkParams = resegRoutines(i).params;
        paramList = buildParams(chkParams, bSearchParams);
        
        if ( isempty(paramList) )
            chkHulls = Segmentation.PartialImageSegment(chanImg, centerPt, subSize, segFunc,{});
            hull = validIntersectHull(chkHulls, centerPt, overlapPoints);
        end
        
        for j=1:size(paramList)
            paramArgs = num2cell(paramList(j,:));
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

function paramList = buildParams(chkParams, bSearchParams)
    paramList = [];
    
    if ( isempty(chkParams) )
        return;
    end
    
    paramCell = {chkParams.value};
    
    % Just use the first value from each parameter set if not searching.
    if ( ~bSearchParams )
        paramList = cellfun(@(x)(x(1)), paramCell);
    end
    
    % Set up a grid of parameter combinations
    paramGrid = cell(1,length(paramCell));
    [paramGrid{:}] = ndgrid(paramCell{:});
    
    reshapeGrid = cellfun(@(x)(reshape(x,numel(x),1)), paramGrid, 'UniformOutput',0);
    
    paramList = [reshapeGrid{:}];
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
