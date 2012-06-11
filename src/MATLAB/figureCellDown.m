%labelID is set if a label is clicked. -1 Should be passed otherwise
function figureCellDown(src, evnt, labelID)
global Figures

currentPoint = get(gca,'CurrentPoint');
if (labelID == -1) %see if we are clicking a label rather than a cell
    Figures.cells.downHullID = FindHull(currentPoint);
else
    Figures.cells.downHullID = labelID;    
end

selectionType = get(Figures.cells.handle,'SelectionType');
%if ( (Figures.cells.downHullID ~= -1) && strcmp(selectionType, 'alt') )
if ( (Figures.cells.downHullID ~= -1) && Figures.controlDown )
    ToggleCellSelection(Figures.cells.downHullID);
    return;
end

%if(strcmp(selectionType,'normal') || strcmp(selectionType,'alt'))
if(strcmp(selectionType,'normal'))
    if(strcmp(Figures.advanceTimerHandle.Running,'on'))
        TogglePlay(src,evnt);
    end
    
    if (~Figures.controlDown )
        ClearCellSelection();
    end
    
    if(Figures.cells.downHullID == -1)
        return
    end
    set(Figures.cells.handle,'WindowButtonUpFcn',@(src,evt) figureCellUp(src,evt));
elseif(strcmp(selectionType,'extend'))
    if(Figures.cells.downHullID == -1)
        AddHull(1);
    else
        AddHull(2);
    end
end
if(strcmp(Figures.advanceTimerHandle.Running,'on'))
    TogglePlay(src,evnt);
end
end