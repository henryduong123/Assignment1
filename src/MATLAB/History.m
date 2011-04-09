function History(action)
%This will keep track of any state changes.
%Possible actions are:
%History('Push') = save current state to the stack
%History('Pop') = retrive the last state
%History('Redo') = will 'push' the last 'pop' back on the stack
%History('Init') = will initilize the history stack
%
%Stack size will be set from CONSTANTS.historySize
%All of the data structures are saved on the stack, so do not set this
%value too high or you might run out of working memory

global CellFamilies CellTracks HashedCells CONSTANTS Figures CellHulls

persistent hist;
persistent top;
persistent bottom;
persistent redo;
persistent empty;
persistent full;

if (isempty(hist))
    top = 1;%points to next place to push or is one greater than the current history
    bottom = 0;%points to the oldest or bottom most valid history
    redo = 0;%points to the youngest or top most valid history
    empty = 1;%flag will be "empty" if only the original opened state is on the stack
    full = 0;%flag
end

switch action
    case 'Push'
        set(Figures.cells.menuHandles.undoMenu,'Enable','on');
        set(Figures.cells.menuHandles.saveMenu,'Enable','on');
        set(Figures.tree.menuHandles.undoMenu,'Enable','on');
        set(Figures.tree.menuHandles.saveMenu,'Enable','on');
        if (empty)
            empty = 0;
            bottom = 1;
        elseif (full)
            %drop oldest history
            if (bottom < CONSTANTS.historySize)
                bottom = bottom + 1;
            else
                bottom = 1;
            end
        end
        
        hist(top).CellFamilies = CellFamilies;
        hist(top).CellTracks = CellTracks;
        hist(top).HashedCells = HashedCells;
        hist(top).CellHulls = CellHulls;
        hist(top).Figures.tree.familyID = Figures.tree.familyID;
        
        redo = top;

        top = top + 1;
        if (top > CONSTANTS.historySize)
            top = 1;
        end
        
        if (top==bottom)
            full = 1;
            empty = 0;
        end
        
        %"Disable" redo
        set(Figures.cells.menuHandles.redoMenu,'Enable','off');
        set(Figures.tree.menuHandles.redoMenu,'Enable','off');
        
    case 'Pop'        
        if (~empty)
            if(redo < top)
                top = top - 2;
            else
                top = top - 1;
            end
            if (top == 0)
                top = CONSTANTS.historySize;
            end
            full = 0;
            
            if (top==bottom)
                empty = 1;
                set(Figures.cells.menuHandles.undoMenu,'Enable','off');
                set(Figures.cells.menuHandles.saveMenu,'Enable','off');
                set(Figures.tree.menuHandles.undoMenu,'Enable','off');
                set(Figures.tree.menuHandles.saveMenu,'Enable','off');
            else
                set(Figures.cells.menuHandles.saveMenu,'Enable','on');
                set(Figures.tree.menuHandles.saveMenu,'Enable','on');
            end
            
            CellFamilies = hist(top).CellFamilies;
            CellTracks = hist(top).CellTracks;
            HashedCells = hist(top).HashedCells;
            CellHulls = hist(top).CellHulls;
            Figures.tree.familyID = hist(top).Figures.tree.familyID;
            
            %increment again so that top is always the next available place
            top = top + 1;
            if (top > CONSTANTS.historySize)
                top = 1;
            end
            
            set(Figures.cells.menuHandles.redoMenu,'Enable','on');
            set(Figures.tree.menuHandles.redoMenu,'Enable','on');
            
            %Update displays
            DrawTree(Figures.tree.familyID);
            DrawCells();
            
            LogAction('Undo',[],[]);
        else
            set(Figures.cells.menuHandles.redoMenu,'Enable','off');
            set(Figures.tree.menuHandles.redoMenu,'Enable','off');
        end
        
    case 'Redo'
        if (redo>=top || (top<bottom && redo<top))
            %redo possible
            
            CellFamilies = hist(top).CellFamilies;
            CellTracks = hist(top).CellTracks;
            HashedCells = hist(top).HashedCells;
            CellHulls = hist(top).CellHulls;
            Figures.tree.familyID = hist(top).Figures.tree.familyID;
            
            %increment again so that top is always the next available place
            top = top + 1;
            if (top > CONSTANTS.historySize)
                top = 1;
            end
            
            empty = 0;
            if(top==bottom)
                full = 1;
            end
            
            %Update displays
            DrawTree(Figures.tree.familyID);
            DrawCells();
            
            if (top>redo)
                set(Figures.cells.menuHandles.redoMenu,'Enable','off');
                set(Figures.cells.menuHandles.undoMenu,'Enable','on');
                set(Figures.tree.menuHandles.redoMenu,'Enable','off');
                set(Figures.tree.menuHandles.undoMenu,'Enable','on');
            end
            
            set(Figures.cells.menuHandles.saveMenu,'Enable','on');
            set(Figures.tree.menuHandles.saveMenu,'Enable','on');
            LogAction('Redo',[],[]);
        end
    case 'Init'
        top = 1;
        bottom = 1;
        redo = 1;
        empty = 0;
        full = 0;
        hist(top).CellFamilies = CellFamilies;
        hist(top).CellTracks = CellTracks;
        hist(top).HashedCells = HashedCells;
        hist(top).CellHulls = CellHulls;
        hist(top).Figures.tree.familyID = Figures.tree.familyID;
        top = 2;
end
end
