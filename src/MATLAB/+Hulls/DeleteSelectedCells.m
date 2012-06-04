% DeleteSelectedCells.m - Remove all currently selected cells from this frame.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
%     Copyright 2011 Andrew Cohen, Eric Wait and Mark Winter
%
%     This file is part of LEVer - the tool for stem cell lineaging. See
%     https://pantherfile.uwm.edu/cohena/www/LEVer.html for details
% 
%     LEVer is free software: you can redistribute it and/or modify
%     it under the terms of the GNU General Public License as published by
%     the Free Software Foundation, either version 3 of the License, or
%     (at your option) any later version.
% 
%     LEVer is distributed in the hope that it will be useful,
%     but WITHOUT ANY WARRANTY; without even the implied warranty of
%     MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
%     GNU General Public License for more details.
% 
%     You should have received a copy of the GNU General Public License
%     along with LEVer in file "gnu gpl v3.txt".  If not, see 
%     <http://www.gnu.org/licenses/>.
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function DeleteSelectedCells()
    global Figures CellFamilies
    
    try
        for i=1:length(Figures.cells.selectedHulls)
            Hulls.RemoveHull(Figures.cells.selectedHulls(i));
        end
        UI.History('Push');
    catch errorMessage
        try
            Error.ErrorHandeling(['RemoveHull(' num2str(hullID) ') -- ' errorMessage.message],errorMessage.stack);
            return
        catch errorMessage2
            fprintf('%s',errorMessage2.message);
            return
        end
    end

    Error.LogAction(['Removed selected cells [' num2str(Figures.cells.selectedHulls) ']'],Figures.cells.selectedHulls);
    
    %if the whole family disapears with this change, pick a diffrent family to display
    if(isempty(CellFamilies(Figures.tree.familyID).tracks))
        for i=1:length(CellFamilies)
            if(~isempty(CellFamilies(i).tracks))
                Figures.tree.familyID = i;
                break
            end
        end
        UI.DrawTree(Figures.tree.familyID);
        UI.DrawCells();
        msgbox(['By removing this cell, the complete tree is no more. Displaying clone rooted at ' num2str(CellFamilies(i).rootTrackID) ' instead'],'Displaying Tree','help');
        return
    end

    UI.DrawTree(Figures.tree.familyID);
    UI.DrawCells();
end