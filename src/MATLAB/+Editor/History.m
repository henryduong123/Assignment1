% History.m -
% This will keep track of any state changes.  Call this function once the
% new state is established. After the changes take place.
% Possible actions are:
% History('Push') = save current state to the stack
% History('Pop') = retrive the last state
% History('Redo') = will 'push' the last 'pop' back on the stack
% History('Init') = will initilize the history stack
% History('Top') = will reinstate the top state without changing any history
% stack pointers.
%
% Stack size will be set from CONSTANTS.historySize
% All of the data structures are saved on the stack, so do not set this
% value too high or you might run out of working memory

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

function History(action)

global CellFamilies CellTracks HashedCells CONSTANTS Figures CellHulls Costs GraphEdits CachedCostMatrix ConnectedDist CellPhenotypes SegmentationEdits
% global test

persistent hist;            %stack
persistent current;         %points to the last state saved on the stack
persistent bottom;          %points to the oldest or bottom most valid history
persistent top;             %points to the youngest or top most valid history
persistent saved;           %flag will be "empty" if only the original opened state is on the stack

if (isempty(hist))
    current = 0;
    bottom = 0;
    top = 0;
    saved = 0;
end

switch action
    case 'Saved'
        saved = current;
        setMenus();
    case 'Push'   
        current = Increment(current);
        
        if (current==bottom)
            if (bottom==saved)
                saved = 0;
            end
            bottom = Increment(bottom);
        end
        
        top = current;
        
        SetHistElement(current);

        setMenus();
    case 'Undo'
        if (current~=bottom)                    
            current = Decrement(current);
            
            GetHistElement(current);
            
            %Update displays
            UI.DrawTree(Figures.tree.familyID);
            UI.DrawCells();
            UI.UpdateSegmentationEditsMenu();
            UI.UpdatePhenotypeMenu();
            Error.LogAction('Undo');
        end
        setMenus();
    case 'Redo'
        if (top~=current)
            %redo possible
            current = Increment(current);
            
            GetHistElement(current);
            
            %Update displays
            UI.DrawTree(Figures.tree.familyID);
            UI.DrawCells();
            UI.UpdateSegmentationEditsMenu();
            UI.UpdatePhenotypeMenu();
            Error.LogAction('Redo');
        end
        setMenus();
    case 'Top'
        GetHistElement(current);
        UI.UpdateSegmentationEditsMenu();
        UI.UpdatePhenotypeMenu();
    case 'Init'
        current = 1;
        bottom = 1;
        top = 1;
        saved = 1;
        SetHistElement(current);
        setMenus();
end

    function setMenus()
        if (current==bottom)
            set(Figures.cells.menuHandles.undoMenu,'Enable','off');
            set(Figures.tree.menuHandles.undoMenu,'Enable','off');
        else
            set(Figures.cells.menuHandles.undoMenu,'Enable','on');
            set(Figures.tree.menuHandles.undoMenu,'Enable','on');
        end
        
        if (current==top)
            set(Figures.cells.menuHandles.redoMenu,'Enable','off');
            set(Figures.tree.menuHandles.redoMenu,'Enable','off');
        else
            set(Figures.cells.menuHandles.redoMenu,'Enable','on');
            set(Figures.tree.menuHandles.redoMenu,'Enable','on');
        end
        
        if (isfield(Figures.cells,'menuHandles') && isfield(Figures.cells.menuHandles,'saveMenu'))
            if (saved==current)
                set(Figures.cells.menuHandles.saveMenu,'Enable','off');
                set(Figures.tree.menuHandles.saveMenu,'Enable','off');
                set(Figures.cells.handle,'Name',[CONSTANTS.datasetName ' Image Data']);
                set(Figures.tree.handle,'Name',[CONSTANTS.datasetName ' Image Data']);
            else
                set(Figures.cells.menuHandles.saveMenu,'Enable','on');
                set(Figures.tree.menuHandles.saveMenu,'Enable','on');
                set(Figures.cells.handle,'Name',[CONSTANTS.datasetName ' Image Data *']);
                set(Figures.tree.handle,'Name',[CONSTANTS.datasetName ' Image Data *']);
            end
        end
    end %setMenu

    function SetHistElement(index)
        hist(index).CellFamilies = CellFamilies;
        hist(index).CellTracks = CellTracks;
        hist(index).HashedCells = HashedCells;
        hist(index).CellHulls = CellHulls;
        hist(index).Costs = Costs;
        hist(index).GraphEdits = GraphEdits;
        hist(index).CachedCostMatrix = CachedCostMatrix;
        hist(index).ConnectedDist = ConnectedDist;
        hist(index).Figures.tree.familyID = Figures.tree.familyID;
        hist(index).CellPhenotypes = CellPhenotypes;
        hist(index).SegmentationEdits = SegmentationEdits;
    end

    function GetHistElement(index)
        CellFamilies = hist(index).CellFamilies;
        CellTracks = hist(index).CellTracks;
        HashedCells = hist(index).HashedCells;
        CellHulls = hist(index).CellHulls;
        Costs = hist(index).Costs;
        GraphEdits = hist(index).GraphEdits;
        CachedCostMatrix = hist(index).CachedCostMatrix;
        ConnectedDist = hist(index).ConnectedDist;
        Figures.tree.familyID = hist(index).Figures.tree.familyID;
        CellPhenotypes = hist(index).CellPhenotypes;
        SegmentationEdits = hist(index).SegmentationEdits;
    end

    function index = Increment(index)
        index = index+1;
        if (index > CONSTANTS.historySize)
            index = 1;
        end
    end

    function index = Decrement(index)
        index = index-1;
        if (index == 0 )
            index = CONSTANTS.historySize;
        end
    end

%test = [test; [current,bottom,top,saved]];
end
