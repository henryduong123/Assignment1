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

function History(action, varargin)
    switch action
        case 'Saved'
            Editor.StackedHistory.SetSaved();
            setMenus();
        case 'Push'
            % Push time context with edit
            if ( isempty(varargin) || ~isnumeric(varargin{1}) )
                varargin{1} = getFigureTime();
            end
            
            Editor.StackedHistory.PushState(varargin{1});
            setMenus();
        case 'Undo'
            if ( Editor.StackedHistory.CanUndo() )
                if ( isempty(varargin) )
                    varargin{1} = '';
                end
                jumpTime = Editor.StackedHistory.UndoState();
                
                if ( strcmpi(varargin{1},'Jump') )
                    setFigureTime(jumpTime);
                end

                updateFigures()
                Error.LogAction('Undo');
            end
            setMenus();
        case 'Redo'
            if ( Editor.StackedHistory.CanRedo() )
                if ( isempty(varargin) )
                    varargin{1} = '';
                end
                jumpTime = Editor.StackedHistory.RedoState();
                
                if ( strcmpi(varargin{1},'Jump') )
                    setFigureTime(jumpTime);
                end
                
                updateFigures();
                Error.LogAction('Redo');
            end
            setMenus();
        case 'Top'
            Editor.StackedHistory.TopState();
            updateFigures();
        case 'Init'
            Editor.StackedHistory.InitStack();
            setMenus();
            
        case 'PushStack'
            Editor.StackedHistory.PushStack();
            setMenus();
        case 'PopStack'
            Editor.StackedHistory.PopStack(varargin{:});
            setMenus();
        case 'DropStack'
            Editor.StackedHistory.DropStack();
            setMenus();
    end
end

function updateFigures()
    global Figures
    if ( isempty(Figures) )
        return;
    end
    
    %Update displays
    UI.DrawTree(Figures.tree.familyID);
    UI.DrawCells();
    UI.UpdateSegmentationEditsMenu();
    UI.UpdatePhenotypeMenu();
end

function setFigureTime(time)
    global Figures
    
    if ( isempty(Figures) )
        return;
    end
    
    Figures.time = time;
end

function time = getFigureTime()
    global Figures
    
    if ( isempty(Figures) )
        time = 1;
        return;
    end
    
    time = Figures.time;
end

function setMenus()
    global Figures CONSTANTS
    
    if ( isempty(Figures) || ~isfield(Figures, 'cells') || ~isfield(Figures, 'tree') )
        return;
    end

    if ( Editor.StackedHistory.CanUndo() )
        set(Figures.cells.menuHandles.undoMenu,'Enable','on');
        set(Figures.tree.menuHandles.undoMenu,'Enable','on');
    else
        set(Figures.cells.menuHandles.undoMenu,'Enable','off');
        set(Figures.tree.menuHandles.undoMenu,'Enable','off');
    end

    if ( Editor.StackedHistory.CanRedo() )
        set(Figures.cells.menuHandles.redoMenu,'Enable','on');
        set(Figures.tree.menuHandles.redoMenu,'Enable','on');
    else
        set(Figures.cells.menuHandles.redoMenu,'Enable','off');
        set(Figures.tree.menuHandles.redoMenu,'Enable','off');
    end

    if (isfield(Figures.cells,'menuHandles') && isfield(Figures.cells.menuHandles,'saveMenu'))
        if ( Editor.StackedHistory.IsSaved() )
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
