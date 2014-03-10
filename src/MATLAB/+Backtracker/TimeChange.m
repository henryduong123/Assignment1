function TimeChange(time)
    global Figures HashedCells

    if(time > length(HashedCells))
        Figures.time = length(HashedCells);
    elseif (time < 1)
        Figures.time = 1;
    else
        Figures.time = time;
    end

%     set(Figures.cells.timeLabel,'String',['Time: ' num2str(Figures.time)]);
%     set(Figures.tree.timeLabel,'String',['Time: ' num2str(Figures.time)]);
    
    Backtracker.UpdateTimeLine();
    Backtracker.DrawCells();
end
