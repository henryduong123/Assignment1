% ErrorHandling.m - 
%***Possibly Throws Error***
% ErrorHandling(errorMessage) will attempt to fix the issue and log the
% error.  If unsuccessful, another log entery will be made and will throw
% the new error.

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

function ErrorHandling(errorMessage, errStack)

global Figures

msgboxHandle = msgbox('Attempting to fix database. Will take some time depending on the size of the database. This window will close when done',...
    'Fixing Database','warn','modal');
Error.LogAction(errorMessage,0,0,errStack);

%let the user know that this might take a while
if ( ~isempty(Figures) )
    set(Figures.tree.handle,'Pointer','watch');
    set(Figures.cells.handle,'Pointer','watch');
end

Editor.History('Top');
Error.OutputDebugErrorFile();
errors = mexIntegrityCheck();
msgbox('Database corrected. Your last action was undone, please try again. If change errors again, save the data file and then send it and the log to the code distributor.',...
    'Database Correct','help','modal');

if (ishandle(msgboxHandle))
    close(msgboxHandle);
end

UI.Progressbar(1);

%let the user know that the drawing is done
if ( ~isempty(Figures) )
    set(Figures.tree.handle,'Pointer','arrow');
    set(Figures.cells.handle,'Pointer','arrow');
end
end
