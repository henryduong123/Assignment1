function LEVer()
%Main program

%--Eric Wait

global Figures

%if LEVer is already opened, save state just in case the User cancels the
%open
if(~isempty(Figures))
    saveEnabled = strcmp(get(Figures.cells.menuHandles.saveMenu,'Enable'),'on');
    History('Push');
    if(~saveEnabled)
        set(Figures.cells.menuHandles.saveMenu,'Enable','off');
    end
end

versionString = '4.3';

if(OpenData(versionString))
    InitializeFigures();
    History('Init');
elseif(~isempty(Figures))
    History('Top');
    DrawTree(Figures.tree.familyID);
    DrawCells();
end

end
