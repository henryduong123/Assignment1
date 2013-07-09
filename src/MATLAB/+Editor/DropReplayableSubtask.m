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