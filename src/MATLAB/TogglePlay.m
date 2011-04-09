function TogglePlay(src,evnt)
% Turn the timer on and off depending on previous state

%--Eric Wait

global Figures

if(strcmp(Figures.advanceTimerHandle.Running,'off'))
    set(Figures.cells.menuHandles.playMenu, 'Checked', 'on');
    start(Figures.advanceTimerHandle);
else
    set(Figures.cells.menuHandles.playMenu, 'Checked', 'off');
    stop(Figures.advanceTimerHandle);
end
end
