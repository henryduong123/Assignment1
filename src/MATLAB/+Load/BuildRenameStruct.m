% [renameStruct,bNeedRename] = BuildRenameStruct(imageName)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
%     Copyright 2016 Drexel University
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


function renameStruct = BuildRenameStruct(imageName)
    renameStruct = [];
    
    paramSet = {'c';'t';'z'};
    paramSize = {2;4;4};
    requireParam = [false,true,false];
    
    paramPattern = cellfun(@(x)(['_(' x ')\d+']), paramSet, 'UniformOutput',false);
    
    [~,fileName,fileExt] = fileparts(imageName);
    [startMatch,tokMatch] = regexpi(fileName, paramPattern, 'start','tokens');

    % If there are multiple matches to the parameter type, take only the one that's furthest in the name.
    bFoundParams = cellfun(@(x)(~isempty(x)),startMatch);
    validStarts = cellfun(@(x)(x(end)), startMatch(bFoundParams));
    validParams = cellfun(@(x)(x{end}{1}), tokMatch(bFoundParams), 'UniformOutput',false);
    
    if ( isempty(validStarts) )
        return;
    end
    
    [~,validParamOrder] = sort(validStarts);
    
    tokPattern = cellfun(@(x)(['_' x '(\d+)']), validParams(validParamOrder), 'UniformOutput',false);
    buildPattern = ['^(.+)' tokPattern{:} '(.*?)$'];
    
    tokMatch = regexp(fileName, buildPattern, 'tokens','once');
    if ( isempty(tokMatch) )
        return;
    end
    
    paramOrder = zeros(1,length(paramSet));
    paramOrder(bFoundParams) = validParamOrder;
    if ( ~all(paramOrder(requireParam)>0) )
        return;
    end
    
    prefixStr = regexptranslate('escape',tokMatch{1});
    postfixStr = regexptranslate('escape',tokMatch{end});
    
    % Escape some possible file name issues
    datasetName = tokMatch{1};
    prefixName = strrep(tokMatch{1},'"','\"');
    prefixName = strrep(prefixName,'''','\''');
    prefixName = strrep(prefixName,'%','%%');
    
    dirBlob = [datasetName '*' fileExt];
    loadPattern = [prefixStr tokPattern{:} postfixStr '\' fileExt];
    
    outParams = cellfun(@(x,y)(['_' x '%0' num2str(y) 'd']), paramSet,paramSize, 'UniformOutput',false);
    outPattern = [prefixName outParams{:} '.tif'];
    
    renameStruct = struct('datasetName',{datasetName}, 'dirBlob',{dirBlob}, 'loadPattern',{loadPattern}, 'outPattern',{outPattern}, 'paramOrder',{paramOrder});
end
