% FigureCellDown(src,evnt)

% ChangeLog:
% NLS 6/11/12 Created

function FigureCellDown(src,evnt, labelID)
    global Figures

    currentPoint = get(gca,'CurrentPoint');
    if (labelID == -1) %see if we are clicking a label rather than a cell
        Figures.cells.downHullID = Hulls.FindHull(currentPoint);
    else
        Figures.cells.downHullID = labelID;    
    end

    selectionType = get(Figures.cells.handle,'SelectionType');
    if ( (Figures.cells.downHullID ~= -1) && Figures.controlDown )
        UI.ToggleCellSelection(Figures.cells.downHullID);
        UI.DrawCells();
        return;
    end

    if(strcmp(selectionType,'normal'))
        if(strcmp(Figures.advanceTimerHandle.Running,'on'))
            UI.TogglePlay(src,evnt);
        end

        if (~Figures.controlDown )
            UI.ClearCellSelection();
        end

        if(Figures.cells.downHullID == -1)
            UI.DrawCells();
            return
        end
        
        UI.ToggleCellSelection(Figures.cells.downHullID);
        
        set(Figures.cells.handle,'WindowButtonUpFcn',@(src,evt) UI.FigureCellUp(src,evt));
    elseif(strcmp(selectionType,'extend'))
        if(Figures.cells.downHullID == -1)
            Segmentation.AddHull(1);
        else
            Segmentation.AddHull(2);
        end
    end
    if(strcmp(Figures.advanceTimerHandle.Running,'on'))
        UI.TogglePlay(src,evnt);
    end
end