% LEVer.m - This is the main program function for the LEVer application.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
%     Copyright 2011 Andrew Cohen, Eric Wait and Mark Winter
%
%     This file is part of LEVer - the tool for stem cell lineaging. See
%     https://pantherfile.uwm.edu/cohena/www/LEVer.html for details
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

function LEVer(varargin)

global Figures ReplayEditActions CONSTANTS

if ( nargin > 0 )
    if ( strcmpi(varargin{1}, '-v') )
        UI.about;
        return;
    end
end

%if LEVer is already opened, save state just in case the User cancels the
%open
previousOpened = 0;
if(~isempty(Figures))
    previousOpened = 1;
end

if(Load.OpenData())
    Editor.ReplayableEditAction(@Editor.InitHistory);
elseif(previousOpened)
    try
        Editor.History('Top');
        %UI.InitializeFigures();
        temp = load(CONSTANTS.matFullFile,'ReplayEditActions');
        ReplayEditActions = temp.ReplayEditActions;
    catch err
    end
end

end
