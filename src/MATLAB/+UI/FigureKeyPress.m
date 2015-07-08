function FigureKeyPress(src,evnt)
    global Figures ResegState

    if strcmp(evnt.Key,'downarrow') || strcmp(evnt.Key,'rightarrow')
        if ( Figures.controlDown )
            time = findMitosis(+1, Figures.time, Figures.tree.familyID);
            UI.TimeChange(time);
        else
            time = Figures.time + 1;
            UI.TimeChange(time);
        end
    elseif strcmp(evnt.Key,'uparrow') || strcmp(evnt.Key,'leftarrow')
        if ( Figures.controlDown )
            time = findMitosis(-1, Figures.time, Figures.tree.familyID);
            UI.TimeChange(time);
        else
            time = Figures.time - 1;
            UI.TimeChange(time);
        end
    elseif  strcmp(evnt.Key,'pagedown')
        time = Figures.time + 5;
        UI.TimeChange(time);
    elseif  strcmp(evnt.Key,'pageup')
        time = Figures.time - 5;
        UI.TimeChange(time);
    elseif strcmp(evnt.Key,'space')
        if ( ~isempty(ResegState) )
            % Toggle reseg playing
            buttonHandles = get(ResegState.toolbar, 'UserData');
            toggleFunc = get(buttonHandles(2), 'ClickedCallback');
            toggleFunc(buttonHandles(2), []);
        else
            % standard movie playing
            UI.TogglePlay(src,evnt); 
        end
    elseif strcmp(evnt.Key,'period')
        if ( ~isempty(ResegState) )
            % Reseg Forward 1 Frame
            buttonHandles = get(ResegState.toolbar, 'UserData');
            toggleFunc = get(buttonHandles(3), 'ClickedCallback');
            toggleFunc(buttonHandles(3), []);
        else
            % step forward one frame
            time = Figures.time + 1;
            UI.TimeChange(time);
        end
    elseif strcmp(evnt.Key,'comma')
        if ( ~isempty(ResegState) )
            % Reseg Backward 1 Frame
            buttonHandles = get(ResegState.toolbar, 'UserData');
            toggleFunc = get(buttonHandles(1), 'ClickedCallback');
            toggleFunc(buttonHandles(1), []);
        else
            % step backward one frame
            time = Figures.time - 1;
            UI.TimeChange(time);
        end
     elseif ( strcmp(evnt.Key,'control') )
         if(~Figures.controlDown)
             %prevent this from getting reset when moving the mouse
            Figures.controlDown = true;
         end
    elseif ( strcmp(evnt.Key,'delete') || strcmp(evnt.Key,'backspace') )
        deleteSelectedCells();
    elseif (strcmp(evnt.Key,'f12'))
        Figures.cells.showInterior = ~Figures.cells.showInterior;
        UI.DrawCells();
        UI.DrawTree(Figures.tree.familyID);
    elseif ( strcmp(evnt.Key,'return') )
        mergeSelectedCells();
    end
end

function mitTime = findMitosis(dirFlag, time, familyID)
    global CellFamilies CellTracks HashedCells
    
    mitTime = 1;
    if ( dirFlag > 0 )
        mitTime = length(HashedCells);
    end
    
    if ( isempty(familyID) )
        return;
    end
    
    famTracks = CellFamilies(familyID).tracks;
    if ( isempty(famTracks) )
        return;
    end
    
    % Append start and end of family and movie to mitosis times list.
    chkTimes = unique([1 CellTracks(famTracks).startTime CellFamilies(familyID).endTime length(HashedCells)]);
    
    if ( dirFlag < 0 )
        idx = find(chkTimes < time, 1, 'last');
    else
        idx = find(chkTimes > time, 1, 'first');
    end
    
    if ( isempty(idx) )
        return;
    end
    
    mitTime = chkTimes(idx);
end

function deleteSelectedCells()
    global Figures CellFamilies
    
    bErr = Editor.ReplayableEditAction(@Editor.DeleteCells, Figures.cells.selectedHulls);
    if ( bErr )
        return;
    end

    UI.ClearCellSelection();
    Error.LogAction(['Removed selected cells [' num2str(Figures.cells.selectedHulls) ']'],Figures.cells.selectedHulls);

    %if the whole family disappears with this change, pick a diffrent family to display
    if(isempty(CellFamilies(Figures.tree.familyID).tracks))
        for i=1:length(CellFamilies)
            if(~isempty(CellFamilies(i).tracks))
                Figures.tree.familyID = i;
                break
            end
        end
    end

    UI.DrawTree(Figures.tree.familyID);
    UI.DrawCells();
end

function mergeSelectedCells()
    global Figures
    
    [bErr deletedCells replaceCell] = Editor.ReplayableEditAction(@Editor.MergeCellsAction, Figures.cells.selectedHulls, Figures.tree.familyID);
    if ( bErr )
        return;
    end
    
    if ( isempty(replaceCell) )
        msgbox(['Unable to merge [' num2str(Figures.cells.selectedHulls) '] in this frame'],'Unable to Merge','help','modal');
        return;
    end
    
    
    UI.ClearCellSelection();
    Error.LogAction('Merged cells', [deletedCells replaceCell], replaceCell);

    UI.DrawTree(Figures.tree.familyID);
    UI.DrawCells();
end

