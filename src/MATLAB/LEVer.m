function LEVer()
%Main program

%--Eric Wait

global Figures

%if LEVer is already opened, save state just in case the User cancels the
%open
if(~isempty(Figures))
    History('Push');
end

if(OpenData())
    InitializeFigures();
    History('Init');
else %if(~isempty(Figures))
    History('Pop');
    DrawTree(Figures.tree.familyID);
    DrawCells();
end
end
