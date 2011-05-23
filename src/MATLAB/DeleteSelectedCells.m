function DeleteSelectedCells()
    global Figures CellFamilies
    
    try
        for i=1:length(Figures.cells.selectedHulls)
            RemoveHull(Figures.cells.selectedHulls(i));
        end
        History('Push');
    catch errorMessage
        try
            ErrorHandeling(['RemoveHull(' num2str(hullID) ') -- ' errorMessage.message],errorMessage.stack);
            return
        catch errorMessage2
            fprintf('%s',errorMessage2.message);
            return
        end
    end

    LogAction(['Removed selected cells [' num2str(Figures.cells.selectedHulls) ']'],Figures.cells.selectedHulls);
    
    %if the whole family disapears with this change, pick a diffrent family to display
    if(isempty(CellFamilies(Figures.tree.familyID).tracks))
        for i=1:length(CellFamilies)
            if(~isempty(CellFamilies(i).tracks))
                Figures.tree.familyID = i;
                break
            end
        end
        DrawTree(Figures.tree.familyID);
        DrawCells();
        msgbox(['By removing this cell, the complete tree is no more. Displaying clone rooted at ' num2str(CellFamilies(i).rootTrackID) ' instead'],'Displaying Tree','help');
        return
    end

    DrawTree(Figures.tree.familyID);
    DrawCells();
end