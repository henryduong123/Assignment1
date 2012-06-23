% [bErr historyAction varargout] = SafeExecuteAction(actPtr, varargin)
% 
% SafeExecuteAction attempts to execute the edit function pointed to by actPtr
% with the rest of the arguments to the function passed on unmodified. If
% an exception is caught during execution of the function an error is logged
% and the edit is undone.

function [bErr historyAction varargout] = SafeExecuteAction(actPtr, varargin)

    varargout = cell(1,max(0,nargout-2));
    try
        [historyAction varargout{:}] = actPtr(varargin{:});
        bErr = 0;
    catch mexcp
        Error.ErrorHandling([func2str(actPtr) ' -- ' mexcp.message], mexcp.stack);
        
        historyAction = '';
        bErr = 1;
    end
end
