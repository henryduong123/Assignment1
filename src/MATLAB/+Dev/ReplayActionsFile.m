% ReplayActionsFile(filename)

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


function ReplayActionsFile(filename)
    
    loadStruct = load(filename, 'ReplayEditActions');
    replayActions = loadStruct.ReplayEditActions;
    
    if ( ~strcmpi(replayActions(1).funcName, 'OriginAction') )
        error('Replayable actions list does not specify origin data hash');
    end
    
    cmpHash = Dev.GetCoreHashList();
    coreHash = replayActions(1).ret{1};
    if ( ~all(strcmpi(cmpHash, coreHash)) )
        error('Current data does not match replay origin data hash.');
    end
    
    if ( replayActions(1).ret{2} == 0 )
        fprintf('WARNING: This data may not be initial segmentation data.\n');
    end
    
    for i=2:length(replayActions)
        chkOut = cell(1,length(replayActions(i).ret));
        funcPtr = replayActions(i).funcPtr;
        funcArgs = replayActions(i).args;
        [bErr chkHash chkOut{:}] = Dev.ReplayEditAction(funcPtr, funcArgs{:});
        
%         cmpHash = replayActions(i).chkHash;
%         if ( ~all(strcmpi(chkHash, cmpHash)) )
%             error('WARNING: Replaying action %d produced different core-hash\n', i);
%         end
        
        if ( bErr ~= replayActions(i).bErr )
            error('WARNING: Replaying action %d produced different result', i);
        end
    end
end