function MoveLine()
    global Figures HashedCells
    
    time = get(Figures.tree.axesHandle,'CurrentPoint');
    time = round(time(3));
    
    if(strcmp(Figures.advanceTimerHandle.Running,'on'))
        UI.TogglePlay([],[]);
    end
    
    if(time < 1)
        Figures.time = 1;
    elseif(time > length(HashedCells))
        Figures.time = length(HashedCells);
    else
        Figures.time = time;
    end
    
    UI.UpdateTimeIndicatorLine();
end
