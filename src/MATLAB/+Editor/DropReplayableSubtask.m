% historyAction = DropReplayableSubtask(taskLabel)
% Edit Action:
%
% Drop a subtask
% Note: Dropping a subtask will not push state to the stack below, however
% current state is not reverted to Top unless followed by an explicit Top
% action.
% 
% The tasklabel should match the task that was added, the labels are only
% an error checking device.

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


function historyAction = DropReplayableSubtask(taskLabel)
    global TaskStack
    
    if ( ~exist('taskLabel','var') )
        taskLabel = num2str(length(TaskStack));
    end
    
    if ( ~strcmpi(taskLabel,TaskStack{end}) )
        error('Task drop mismatch');
    end
    
    TaskStack = TaskStack(1:end-1);
    
    historyAction = 'DropStack';
end