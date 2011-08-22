% UpdateTimeIndicatorLine.m - Changes the postition of the Red Line that
% indicates the current time displayed

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

function UpdateTimeIndicatorLine()

global Figures

if(ishandle(Figures.tree.timeIndicatorLine))
    set(Figures.tree.timeIndicatorLine,...
        'YData',        [Figures.time Figures.time]);
else
    Figures.tree.timeIndicatorLine = line(...
        get(Figures.tree.axesHandle,'XLim'),...
        [Figures.time Figures.time],...
        'color',        'red',...
        'linewidth',    1,...
        'EraseMode',    'xor',...
        'Tag',          'timeIndicatorLine',...
        'Parent',       Figures.tree.axesHandle);
end
set(Figures.tree.timeLabel,'String',['Time: ' num2str(Figures.time)]);
end
