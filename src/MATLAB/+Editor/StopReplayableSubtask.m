% historyAction = StopReplayableSubtask(time, taskLabel)
%
% Stop a subtask, the tasklabel should match the task which was added, the
% labels are only an error checking device.

function historyAction = StopReplayableSubtask(time, taskLabel)
    global TaskStack
    
    if ( ~exist('taskLabel','var') )
        taskLabel = num2str(length(TaskStack));
    end
    
    if ( ~strcmpi(taskLabel,TaskStack{end}) )
        error('Task stop mismatch');
    end
    
    TaskStack = TaskStack(1:end-1);
    
    historyAction.action = 'PopStack';
    historyAction.arg = time;
end
