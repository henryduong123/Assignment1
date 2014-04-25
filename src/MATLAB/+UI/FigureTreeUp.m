function FigureTreeUp(src,evnt)
    global Figures
    
    set(Figures.tree.handle, 'WindowButtonMotionFcn','');
    
    if(strcmp(get(Figures.tree.handle,'SelectionType'),'normal'))
        UI.TimeChange(Figures.time);
    end
end
