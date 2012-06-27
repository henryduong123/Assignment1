% [bErr varargout] = ReplayEditAction(actPtr, varargin)
% 
% ReplayEditAction attempts to replay an action from an editaction list.

function [bErr chkHash varargout] = ReplayEditAction(actPtr, varargin)

    varargout = cell(1,max(0,nargout-2));
    [bErr historyAction varargout{:}] = Editor.SafeExecuteAction(actPtr, varargin{:});
    
    if ( ~bErr )
        if ( ~isempty(historyAction) )
            Editor.History(historyAction);
        end
    end
    
    chkHash = Dev.GetCoreHashList();
end