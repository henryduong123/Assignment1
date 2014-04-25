function Play(src,evt)
    global Figures HashedCells

    time = Figures.time + 1;

    if(time >= length(HashedCells))
        time = 1;
    end

    UI.TimeChange(time);
end
