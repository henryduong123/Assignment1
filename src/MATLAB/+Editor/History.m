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

global CellFamilies CellTracks HashedCells CONSTANTS Figures CellHulls CellFeatures Costs GraphEdits CachedCostMatrix ConnectedDist CellPhenotypes SegmentationEdits

persistent hist;            %stack
persistent current;         %points to the last state saved on the stack
persistent bottom;          %points to the oldest or bottom most valid history
persistent top;             %points to the youngest or top most valid history
persistent empty;           %flag will be "empty" if only the original opened state is on the stack
persistent full;            %flag
persistent exceededLimit;   %flag to denote if CONSTANTS.historySize has ever been reached

if (isempty(hist))
    current = 1;
    bottom = 0;
    top = 0;
    empty = 1;
    full = 0;
    exceededLimit = 0;
end

switch action
    case 'Push'
        if (empty)
            empty = 0;
            bottom = 1;
        elseif (full)
            %drop oldest history
            exceededLimit = 1;
            if (bottom < CONSTANTS.historySize)
                bottom = bottom + 1;
            else
                bottom = 1;
            end
        end

        current = current + 1;
        if (current > CONSTANTS.historySize)
            current = 1;
        end
        
        top = current;
        
        SetHistElement(current);
        
        if (current==bottom)
            full = 1;
            empty = 0;
        end
        setMenus();
    case 'Pop'        
        if (~empty)
            if (current == 0)
                current = CONSTANTS.historySize;
            end
            
            if (current==bottom && ~full)
                empty = 1;
            end
            
            full = 0;
            
            current = current - 1;
            
            if(current==0)
                current = CONSTANTS.historySize;
            end
            
            GetHistElement(current);
            
            %Update displays
            UI.DrawTree(Figures.tree.familyID);
            UI.DrawCells();
            setMenus();
            Error.LogAction('Undo');
        end
    case 'Redo'
        if (top>current || (bottom>=top && top~=current))
            %redo possible
            current = current + 1;
            if (current > CONSTANTS.historySize)
                current = 1;
            end
            
            GetHistElement(current);
            
            empty = 0;
            if(current==bottom)
                full = 1;
            end
            
            %Update displays
            UI.DrawTree(Figures.tree.familyID);
            UI.DrawCells();
            setMenus();
            Error.LogAction('Redo');
        end
    case 'Top'
         GetHistElement(current);
    case 'Init'
        current = 1;
        bottom = 1;
        top = 1;
        empty = 0;
        full = 0;
        exceededLimit = 0;
        SetHistElement(current);
        set(Figures.cells.menuHandles.redoMenu,'Enable','off');
        set(Figures.tree.menuHandles.redoMenu,'Enable','off');
        set(Figures.cells.menuHandles.undoMenu,'Enable','off');
        set(Figures.tree.menuHandles.undoMenu,'Enable','off');
        set(Figures.cells.menuHandles.saveMenu,'Enable','off');
        set(Figures.tree.menuHandles.saveMenu,'Enable','off');
end

    function setMenus()
        if(top>bottom)
            %not "rolled over"
            if(current<top)
                %redo possible
                set(Figures.cells.menuHandles.redoMenu,'Enable','on');
                set(Figures.tree.menuHandles.redoMenu,'Enable','on');
            else
                set(Figures.cells.menuHandles.redoMenu,'Enable','off');
                set(Figures.tree.menuHandles.redoMenu,'Enable','off');
            end
            if(current>bottom)
                %undo possible
                set(Figures.cells.menuHandles.undoMenu,'Enable','on');
                set(Figures.tree.menuHandles.undoMenu,'Enable','on');
            else
                set(Figures.cells.menuHandles.undoMenu,'Enable','off');
                set(Figures.tree.menuHandles.undoMenu,'Enable','off');
            end
        elseif(top==bottom && ~empty)
            if(current~=top)
                %redo and undo possible
                set(Figures.cells.menuHandles.redoMenu,'Enable','on');
                set(Figures.tree.menuHandles.redoMenu,'Enable','on');
                set(Figures.cells.menuHandles.undoMenu,'Enable','on');
                set(Figures.tree.menuHandles.undoMenu,'Enable','on');
            else
                set(Figures.cells.menuHandles.redoMenu,'Enable','off');
                set(Figures.tree.menuHandles.redoMenu,'Enable','off');
                if(~full)
                    set(Figures.cells.menuHandles.undoMenu,'Enable','off');
                    set(Figures.tree.menuHandles.undoMenu,'Enable','off');
                else
                    set(Figures.cells.menuHandles.undoMenu,'Enable','on');
                    set(Figures.tree.menuHandles.undoMenu,'Enable','on');
                end
            end
            
        else
            %"rolled over"
            if(current>=bottom || current<top)
                %redo possible
                set(Figures.cells.menuHandles.redoMenu,'Enable','on');
                set(Figures.tree.menuHandles.redoMenu,'Enable','on');
            else
                set(Figures.cells.menuHandles.redoMenu,'Enable','off');
                set(Figures.tree.menuHandles.redoMenu,'Enable','off');
            end
            if(current>bottom || current<=top)
                %undo possible
                set(Figures.cells.menuHandles.undoMenu,'Enable','on');
                set(Figures.tree.menuHandles.undoMenu,'Enable','on');
            else
                set(Figures.cells.menuHandles.undoMenu,'Enable','off');
                set(Figures.tree.menuHandles.undoMenu,'Enable','off');
            end
        end
        
        %check to see if we are at the original state from the .mat file
        if(exceededLimit)
            set(Figures.cells.menuHandles.saveMenu,'Enable','on');
            set(Figures.tree.menuHandles.saveMenu,'Enable','on');
        else
            if(empty)
                set(Figures.cells.menuHandles.saveMenu,'Enable','off');
                set(Figures.tree.menuHandles.saveMenu,'Enable','off');
            else
                set(Figures.cells.menuHandles.saveMenu,'Enable','on');
                set(Figures.tree.menuHandles.saveMenu,'Enable','on');
            end
        end
    end %setMenu

    function SetHistElement(index)
        hist(index).CellFamilies = CellFamilies;
        hist(index).CellTracks = CellTracks;
        hist(index).HashedCells = HashedCells;
        hist(index).CellHulls = CellHulls;
        hist(index).CellFeatures = CellFeatures;
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
        CellFeatures = hist(index).CellFeatures;
        Costs = hist(index).Costs;
        GraphEdits = hist(index).GraphEdits;
        CachedCostMatrix = hist(index).CachedCostMatrix;
        ConnectedDist = hist(index).ConnectedDist;
        Figures.tree.familyID = hist(index).Figures.tree.familyID;
        CellPhenotypes = hist(index).CellPhenotypes;
        SegmentationEdits = hist(index).SegmentationEdits;
        UI.UpdateSegmentationEditsMenu();
    end
end
