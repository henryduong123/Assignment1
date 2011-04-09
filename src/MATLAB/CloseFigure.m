function CloseFigure(varargin)
global Figures
if(strcmp(get(Figures.cells.menuHandles.saveMenu,'Enable'),'on'))
    choice = questdlg('Save current edits before closing?','Closing','Yes','No','Cancel','Cancel');
    switch choice
        case 'Yes'
            SaveData();
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
