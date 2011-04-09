function TimeChange(time)
%Takes the given time and changes the figures to that time or the closest
%time within [1 length(HashedCells)]

%--Eric Wait

global Figures HashedCells

if(time > length(HashedCells))
    Figures.time = length(HashedCells);
elseif (time < 1)
    Figures.time = 1;
else
    Figures.time = time;
end

set(Figures.cells.timeLabel,'String',['Time: ' num2str(Figures.time)]);
set(Figures.tree.timeLabel,'String',['Time: ' num2str(Figures.time)]);
UpdateTimeIndicatorLine();
DrawCells();
end
