% historyAction = StartReplayableSubtask(taskLabel)
%
% Begin a new subtask, this creates a new history stack to be used for the
% task.

function historyAction = StartReplayableSubtask(taskLabel)
    global TaskStack
    
    if ( ~exist('taskLabel','var') )
        taskLabel = num2str(length(TaskStack)+1);
    end
    
    TaskStack = [TaskStack; {taskLabel}];
    
    historyAction = 'PushStack';
end
