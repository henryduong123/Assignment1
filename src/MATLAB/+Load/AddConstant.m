% AddConstant(field,val,overWrite) will add the given field to the
% CONSTANTS global variable and assign it the given value.
% overWrite - is an optional flag {0,1} that will force the new value if
% the field exists. Zero will keep the old value, One will overwrite the
% current value

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

function AddConstant(fieldPath, newValue, overwrite)

global CONSTANTS

if(~exist('overwrite','var'))
    overwrite = 0;
end

if ( isempty(fieldPath) )
    return;
end

CONSTANTS = updateField(CONSTANTS, fieldPath, newValue, overwrite);
end

function outStruct = updateField(inStruct, fieldPath, newValue, overwrite)
    outStruct = inStruct;
    
    [subField, remStr] = strtok(fieldPath,'.');
    if ( isempty(remStr) )
        if ( overwrite || ~isfield(inStruct,subField) )
            outStruct.(subField) = newValue;
        end
        return;
    end
    
    if ( ~isfield(inStruct,subField) )
        outStruct.(subField) = [];
    end
    
    outStruct.(subField) = updateField(outStruct.(subField), remStr, newValue, overwrite);
end
