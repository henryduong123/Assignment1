function CloseFigure(varargin)
%Closes both figures and cleans up the Figures global var

%--Eric Wait

global Figures
if(isempty(Figures))
    set(gcf,'CloseRequestFcn','remove');
    delete(gcf);
    return
end
if(strcmp(get(Figures.cells.menuHandles.saveMenu,'Enable'),'on'))
    choice = questdlg('Save current edits before closing?','Closing','Yes','No','Cancel','Cancel');
    switch choice
        case 'Yes'
            SaveData(0);
        case 'Cancel'
            return
        case 'No'
            %do nothing, just close
        otherwise
            return
    end
end
if(~isempty(Figures.advanceTimerHandle))
    delete(Figures.advanceTimerHandle);
end
delete(figure(Figures.cells.handle));
delete(figure(Figures.tree.handle));
Figures = [];
end
