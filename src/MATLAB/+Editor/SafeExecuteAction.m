% [bErr historyAction varargout] = SafeExecuteAction(actPtr, varargin)
% 
% SafeExecuteAction attempts to execute the edit function pointed to by actPtr
% with the rest of the arguments to the function passed on unmodified. If
% an exception is caught during execution of the function an error is logged
% and the edit is undone.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
%     Copyright 2016 Drexel University
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


function [bErr historyAction varargout] = SafeExecuteAction(actPtr, varargin)

    varargout = cell(1,max(0,nargout-2));
    
    if ( Helper.IsDebug() )
        [historyAction varargout{:}] = actPtr(varargin{:});
        bErr = 0;
    else    
        try
            [historyAction varargout{:}] = actPtr(varargin{:});
            bErr = 0;
        catch mexcp
            Error.ErrorHandling([func2str(actPtr) ' -- ' mexcp.message], mexcp.stack);

            historyAction = '';
            bErr = 1;
        end
    end
end
