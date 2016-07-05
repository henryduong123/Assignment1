% newStruct = MakeInitStruct(outStruct, inStruct)

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


% Output a structure entry with fields same as outStruct and any fields
% with the same name copied from inStruct (all others empty)

function newStruct = MakeInitStruct(templateStruct, initStruct)
    if ( isempty(fieldnames(templateStruct)) )
        error('Template structure must have at least one field');
    end

    initSize = size(initStruct);
    [outFields newStruct] = initNonemptyStruct(templateStruct, initSize);
    
    % If this isn't an empty structure, then we can force logical fields
    bLogical = false(1,length(outFields));
    if ( ~isempty(templateStruct) )
        bLogical = structfun(@(x)(islogical(x)), templateStruct(1));
    end
    
    for i=1:length(outFields)
        if ( ~bLogical(i) )
            if ( isfield(initStruct,outFields(i)) )
                [newStruct.(outFields{i})] = deal(initStruct.(outFields{i}));
            else
                [newStruct.(outFields{i})] = deal([]);
            end
        else
            if ( isfield(initStruct,outFields(i)) )
                logicalData = arrayfun(@(x)(forceLogical(x.(outFields{i}))), initStruct, 'UniformOutput',false);
                [newStruct.(outFields{i})] = deal(logicalData{:});
            else
                [newStruct.(outFields{i})] = deal(false);
            end
        end
    end
end

function [outFields tempStruct] = initNonemptyStruct(templateStruct, structSize)
    outFields = fieldnames(templateStruct);
    fieldStruct = cell2struct(cell(1,length(outFields)), outFields, 2);
    
    tempStruct = repmat(fieldStruct, structSize);
end

function bValue = forceLogical(value)
    bValue = (value ~= 0);
end
