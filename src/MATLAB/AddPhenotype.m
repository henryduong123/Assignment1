function AddPhenotype(NewPhenotype)
global CellPhenotypes

PhenoMenu = get(CellPhenotypes.contextMenuID(1),'parent');
i=length(CellPhenotypes.descriptions)+1;
CellPhenotypes.contextMenuID(i)=uimenu(PhenoMenu,...
    'Label',        NewPhenotype{1},...
    'CallBack',     @Phenotypes);
CellPhenotypes.descriptions(i)=NewPhenotype;
end