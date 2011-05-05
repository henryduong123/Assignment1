%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
%     This file is part of LEVer.exe
%     (C) 2011 Andrew Cohen, Eric Wait and Mark Winter
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function AddConstant(field,val,overWrite)
% AddConstant(field,val,overWrite) will add the given field to the
% CONSTANTS global variable and assign it the given value.
% overWrite - is an optional flag {0,1} that will force the new value if
% the field exists. Zero will keep the old value, One will overwrite the
% current value


global CONSTANTS

if(~exist('overWrite','var'))
    overWrite = 0;
end

if(~isfield(CONSTANTS,field))
    CONSTANTS.(field) = val;
elseif(overWrite)
    CONSTANTS.(field) = val;
end
end