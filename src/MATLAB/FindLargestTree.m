function FindLargestTree(src,evnt)
global CellFamilies Figures

maxID = 1;
for i=2:length(CellFamilies)
    if(length(CellFamilies(maxID).tracks) < length(CellFamilies(i).tracks))
        maxID = i;
    end
end 
if(isfield(Figures.tree,'FamilyID') && Figures.tree.familyID == maxID),return,end

Figures.tree.familyID = maxID;
DrawTree(maxID);
DrawCells();
end