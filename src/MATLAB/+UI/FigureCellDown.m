% FigureCellDown(src,evnt)

% ChangeLog:
% NLS 6/11/12 Created

function FigureCellDown(src,evnt, labelID)
    global Figures

    % Stop play as soon as click occurs
    if(strcmp(Figures.advanceTimerHandle.Running,'on'))
        UI.TogglePlay(src,evnt);
    end
    
    currentPoint = get(gca,'CurrentPoint');
    Figures.downClickPoint = currentPoint(1,1:2);
    
    if ( strcmpi(Figures.cells.editMode, 'mitosis') )
        createMitosisDragLine(currentPoint);
        set(Figures.cells.handle, 'WindowButtonMotionFcn', @UI.FigureCellDrag);
        set(Figures.cells.handle,'WindowButtonUpFcn',@(src,evt) UI.FigureCellUp(src,evt));
        return;
    end
    
    if (labelID == -1) %see if we are clicking a label rather than a cell
        Figures.cells.downHullID = Hulls.FindHull(Figures.time, currentPoint);
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
        if (~Figures.controlDown )
            UI.ClearCellSelection();
        end

        if(Figures.cells.downHullID == -1)
            UI.DrawCells();
            return
        end
        
        UI.ToggleCellSelection(Figures.cells.downHullID);
        
        set(Figures.cells.handle, 'WindowButtonMotionFcn', @UI.FigureCellDrag);
        set(Figures.cells.handle,'WindowButtonUpFcn',@(src,evt) UI.FigureCellUp(src,evt));
    elseif(strcmp(selectionType,'extend'))
        if(Figures.cells.downHullID == -1)
            Editor.AddHull(1);
        else
            Editor.AddHull(2);
        end
    end
end

function createMitosisDragLine(currentPoint)
    global Figures MitDragCoords
    
    MitDragCoords = [currentPoint(1,1:2).' currentPoint(1,1:2).'];
    
    if ( Helper.NonEmptyField(Figures.cells, 'dragElements') )
        structfun(@(x)(delete(x)), Figures.cells.dragElements);
        Figures.cells.dragElements = [];
    end
    
    curAx = get(Figures.cells.handle, 'CurrentAxes');
    
    Figures.cells.dragElements.line = line(MitDragCoords(1,:), MitDragCoords(2,:), 'Parent',curAx, 'Color','r');
end

