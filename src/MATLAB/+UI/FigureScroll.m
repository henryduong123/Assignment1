function FigureScroll(src,evnt)
    global Figures
    
    time = Figures.time + evnt.VerticalScrollCount;
    
    UI.TimeChange(time);
end
