
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

function helpStruct = FrameSegHelp(funcName)
    helpStruct = [];
    
    SupportedTypes = Load.GetSupportedCellTypes();
    segInfo = [SupportedTypes.segRoutine];
    
    segFuncs = arrayfun(@(x)(char(x.func)), segInfo, 'UniformOutput',false);
    funcIdx = find(strcmp(segFuncs, funcName));
    if ( isempty(funcIdx) )
        return;
    end
    
    if ( isdeployed() )
        helpStruct = Dev.CompiledSegHelp(funcName);
        return;
    end
    
    chkInfo = segInfo(funcIdx);
    chkName = char(chkInfo.func);
    
    helpStruct.func = chkName;
    helpStruct.summary = '';
    helpStruct.paramHelp = cell(length(chkInfo.params),1);
    
    helpString = help(chkName);
    if ( isempty(helpString) )
        helpString = chkName;
    end
    
    %% Get a segmentation summary from function help.
    tokMatch = regexp(helpString,'^\s*FrameSegmentor_*\w*\s*-\s*(.+?)^\s*$', 'once','tokens','lineanchors');
    if ( isempty(tokMatch) )
        helpLines = strsplit(helpString,'\n');
        funcSummary = escapeString(strtrim(helpLines{1}));
    else
        funcSummary = escapeString(tokMatch{1});
    end
    
    %% Get parameter help if available in function documentation.
    helpStruct.summary = funcSummary;
    for i=1:length(chkInfo.params)
        paramName = chkInfo.params(i).name;
        
        helpStruct.paramHelp{i} = '';
        tokMatch = regexp(helpString,['^\s*(' paramName '.+?)^\s*$'], 'once','tokens','lineanchors');
        if ( ~isempty(tokMatch) )
            helpStruct.paramHelp{i} = escapeString(tokMatch{1});
        end
    end
end

% Escape inStr so that safeStr will reproduce inStr when passed as a format string to sprintf()
function safeStr = escapeString(inStr)
    escStr = {'%%','\\','\a','\b','\f','\n','\r','\t','\v'};
    escChars = num2cell(sprintf([escStr{:}]));
    
    escStr = [{''''''},escStr];
    escChars = [{''''},escChars];
    
    escMap = containers.Map(escChars,escStr);
    
    safeStr = '';
    for i=1:length(inStr)
        nextChar = inStr(i);
        if ( isKey(escMap,nextChar) )
            nextChar = escMap(nextChar);
        end
        
        safeStr = [safeStr nextChar];
    end
end
