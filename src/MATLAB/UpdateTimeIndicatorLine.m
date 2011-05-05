%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
%     This file is part of LEVer.exe
%     (C) 2011 Andrew Cohen, Eric Wait and Mark Winter
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function UpdateTimeIndicatorLine()
%Changes the postition of the Red Line that indicates the current time
%displayed


global Figures

if(ishandle(Figures.tree.timeIndicatorLine))
    set(Figures.tree.timeIndicatorLine,...
        'YData',        [Figures.time Figures.time]);
else
    Figures.tree.timeIndicatorLine = line(...
        get(Figures.tree.axesHandle,'XLim'),...
        [Figures.time Figures.time],...
        'color',        'red',...
        'linewidth',    1,...
        'EraseMode',    'xor',...
        'Tag',          'timeIndicatorLine',...
        'Parent',       Figures.tree.axesHandle);
end
set(Figures.tree.timeLabel,'String',['Time: ' num2str(Figures.time)]);
end
