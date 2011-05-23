%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
%     This file is part of LEVer.exe
%     (C) 2011 Andrew Cohen, Eric Wait and Mark Winter
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function TimeChange(time)
%Takes the given time and changes the figures to that time or the closest
%time within [1 length(HashedCells)]


global Figures HashedCells

if(time > length(HashedCells))
    Figures.time = length(HashedCells);
elseif (time < 1)
    Figures.time = 1;
else
    Figures.time = time;
end

ClearCellSelection();

set(Figures.cells.timeLabel,'String',['Time: ' num2str(Figures.time)]);
set(Figures.tree.timeLabel,'String',['Time: ' num2str(Figures.time)]);
UpdateTimeIndicatorLine();
DrawCells();
end
