%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
%     This file is part of LEVer.exe
%     (C) 2011 Andrew Cohen, Eric Wait and Mark Winter
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

function LEVer()
%Main program


global Figures

%if LEVer is already opened, save state just in case the User cancels the
%open
if(~isempty(Figures))
    saveEnabled = strcmp(get(Figures.cells.menuHandles.saveMenu,'Enable'),'on');
    History('Push');
    if(~saveEnabled)
        set(Figures.cells.menuHandles.saveMenu,'Enable','off');
    end
end

versionString = '5.1 E';

if(OpenData(versionString))
    InitializeFigures();
    History('Init');
elseif(~isempty(Figures))
    History('Top');
    DrawTree(Figures.tree.familyID);
    DrawCells();
end

end
