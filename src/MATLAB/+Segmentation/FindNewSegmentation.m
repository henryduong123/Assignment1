
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
%     Copyright 2011-2016 Andrew Cohen
%
%     This file is part of LEVer - the tool for stem cell lineaging. See
%     http://n2t.net/ark:/87918/d9rp4t for details
% 
%     LEVer is free software: you can redistribute it and/or modify
%     it under the terms of the GNU General Public License as published by
%     the Free Software Foundation, either version 3 of the License, or
%     (at your option) any later version.
% 
%     LEVer is distributed in the hope that it will be useful,
%     but WITHOUT ANY WARRANTY; without even the implied warranty of
%     MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
%     GNU General Public License for more details.
% 
%     You should have received a copy of the GNU General Public License
%     along with LEVer in file "gnu gpl v3.txt".  If not, see 
%     <http://www.gnu.org/licenses/>.
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


function hull = FindNewSegmentation(chanImg, centerPt, subSize, bSearchParams, overlapPoints, time)
    global CONSTANTS
    
    typeParams = Load.GetCellTypeStructure(CONSTANTS.cellType);
    
    origSegName = char(CONSTANTS.segInfo.func);
    resegRoutines = typeParams.resegRoutines;
    for i=1:length(resegRoutines)
        segFunc = resegRoutines(i).func;
        segName = char(segFunc);
        
        origParams = [];
        if ( strcmp(origSegName,segName) )
            origParams = CONSTANTS.segInfo.params;
        end
        
        % Search the range of each entry if we are searching.
        chkParams = resegRoutines(i).params;
        paramList = buildParams(chkParams, bSearchParams, origParams);
        
        if ( isempty(paramList) )
            chkHulls = Segmentation.PartialImageSegment(chanImg, centerPt, subSize, CONSTANTS.primaryChannel, segFunc,{});
            hull = validIntersectHull(chkHulls, centerPt, overlapPoints);
        end
        
        for j=1:size(paramList)
            paramArgs = num2cell(paramList(j,:));
            chkHulls = Segmentation.PartialImageSegment(chanImg, centerPt, subSize, CONSTANTS.primaryChannel, segFunc, paramArgs);

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

function paramList = buildParams(chkParams, bSearchParams, origParams)
    paramList = [];
    
    if ( isempty(chkParams) )
        return;
    end
    
    % Fill in any [] param values with original params if possible
    paramCell = {chkParams.value};
    emptyParams = find(cellfun(@(x)(isempty(x)), paramCell));
    origNames = {origParams.name};
    for i=1:length(emptyParams)
        paramName = chkParams(emptyParams(i)).name;
        matchIdx = find(strcmp(paramName, origNames));
        if ( isempty(matchIdx) )
            error(['No matching parameter name in segmentation function: ' emptyParams(i).name]);
        end
        
        paramCell{emptyParams(i)} = origParams(matchIdx).value;
    end
    
    % Just use the first value from each parameter set if not searching.
    if ( ~bSearchParams )
        paramList = cellfun(@(x)(x(1)), paramCell);
        return;
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
