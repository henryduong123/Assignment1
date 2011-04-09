function TogglePlay(src,evnt)
global Figures
if(strcmp(Figures.advanceTimerHandle.Running,'off'))
    set(Figures.cells.menuHandles.playMenu, 'Checked', 'on');
    start(Figures.advanceTimerHandle);
else
    set(Figures.cells.menuHandles.playMenu, 'Checked', 'off');
    stop(Figures.advanceTimerHandle);
end
end
