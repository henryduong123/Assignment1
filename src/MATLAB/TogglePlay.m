%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
%     This file is part of LEVer.exe
%     (C) 2011 Andrew Cohen, Eric Wait and Mark Winter
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function TogglePlay(src,evnt)
% Turn the timer on and off depending on previous state


global Figures

if(strcmp(Figures.advanceTimerHandle.Running,'off'))
    set(Figures.cells.menuHandles.playMenu, 'Checked', 'on');
    start(Figures.advanceTimerHandle);
else
    set(Figures.cells.menuHandles.playMenu, 'Checked', 'off');
    stop(Figures.advanceTimerHandle);
end
end
