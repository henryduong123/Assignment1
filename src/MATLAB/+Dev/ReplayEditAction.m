% [bErr varargout] = ReplayEditAction(actPtr, varargin)
% 
% ReplayEditAction attempts to replay an action from an editaction list.

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


function [bErr chkHash varargout] = ReplayEditAction(actPtr, varargin)

    varargout = cell(1,max(0,nargout-2));
    [bErr historyAction varargout{:}] = Editor.SafeExecuteAction(actPtr, varargin{:});
    
    if ( ~bErr )
        if ( ~isempty(historyAction) )
            Editor.History(historyAction);
        end
    end
    
%     chkHash = Dev.GetCoreHashList();
    chkHash = {};
end