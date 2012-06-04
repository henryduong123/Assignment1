% TimeChange.m - Takes the given time and changes the figures to that time
% or the closest time within [1 length(HashedCells)]

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

function TimeChange(time)

global Figures HashedCells

if(time > length(HashedCells))
    Figures.time = length(HashedCells);
elseif (time < 1)
    Figures.time = 1;
else
    Figures.time = time;
end

UI.ClearCellSelection();

set(Figures.cells.timeLabel,'String',['Time: ' num2str(Figures.time)]);
set(Figures.tree.timeLabel,'String',['Time: ' num2str(Figures.time)]);
UI.UpdateTimeIndicatorLine();
UI.DrawCells();
end
