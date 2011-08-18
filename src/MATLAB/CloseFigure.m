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

function CloseFigure(varargin)
%Closes both figures and cleans up the Figures global var


global Figures
if(isempty(Figures))
    set(gcf,'CloseRequestFcn','remove');
    delete(gcf);
    return
end
if(strcmp(get(Figures.cells.menuHandles.saveMenu,'Enable'),'on'))
    choice = questdlg('Save current edits before closing?','Closing','Yes','No','Cancel','Cancel');
    switch choice
        case 'Yes'
            SaveData(0);
        case 'Cancel'
            return
        case 'No'
            %do nothing, just close
        otherwise
            return
    end
end
if(~isempty(Figures.advanceTimerHandle))
    delete(Figures.advanceTimerHandle);
end
delete(figure(Figures.cells.handle));
delete(figure(Figures.tree.handle));
Figures = [];
end
