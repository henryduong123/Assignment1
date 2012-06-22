% [bErr varargout] = ReplayableEditAction(actPtr, varargin)
% 
% ReplayableEditAction attempts to execute the edit function pointed to by actPtr
% with the rest of the arguments to the function passed on unmodified. If
% an exception is caught during execution of the function an error is logged
% and the edit is undone.
% 
% Regardless of success, the action and all arguments are added to the end
% of the replay list.

function [bErr varargout] = ReplayableEditAction(actPtr, varargin)
    global ReplayEditActions
    
    newAct = struct('funcName',{func2str(actPtr)}, 'funcPtr',{actPtr}, 'args',{varargin}, 'ret',{{}}, 'bErr',{0}, 'ctx',{[]});
    ReplayEditActions = [ReplayEditActions; newAct];
    
    varargout = cell(1,max(0,nargout-1));
    [bErr varargout{:}] = Editor.SafeExecuteAction(actPtr, varargin{:});
    
    ReplayEditActions(end).bErr = bErr;
    if ( ~bErr )
        ReplayEditActions(end).ret = varargout;
    end
end