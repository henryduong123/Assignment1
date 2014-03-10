function SetFigureHandlers()
    global Figures
    
    % Set common handlers for both windows
    hCommon = [Figures.tree.handle Figures.cells.handle];
    for i=1:length(hCommon)
        set(hCommon(i), 'WindowScrollWheelFcn',@scrollFunction);
        set(hCommon(i), 'KeyPressFcn',@keyPress);
        set(hCommon(i), 'CloseRequestFcn',@closeFigures);
    end
    
    set(Figures.tree.handle, 'KeyPressFcn',@treeKeyPress);
    set(Figures.tree.handle, 'WindowButtonDownFcn',@figureTreeDown);
    set(Figures.tree.handle, 'WindowButtonUpFcn',@figureTreeUp);
    
    set(Figures.cells.handle, 'KeyPressFcn',@cellKeyPress);
    set(Figures.cells.handle, 'WindowButtonDownFcn',@figureCellsDown);
    set(Figures.cells.handle, 'WindowButtonUpFcn',@figureCellsUp);
    
    createMenu();
    
    Figures.cells.dragLine = [];
end

%%%%%%%%%%%%%%%%%%%%%%
% Figure event handling

function scrollFunction(src,evt)
    global Figures
    
    time = Figures.time + evt.VerticalScrollCount;
    Backtracker.TimeChange(time);
end

function treeKeyPress(src,evt)
    global Figures

    if ( strcmpi(evt.Key,'downarrow') || strcmp(evt.Key,'rightarrow') )
        time = Figures.time + 1;
        Backtracker.TimeChange(time);
    elseif ( strcmpi(evt.Key,'uparrow') || strcmp(evt.Key,'leftarrow') )
        time = Figures.time - 1;
        Backtracker.TimeChange(time);
    elseif ( strcmpi(evt.Key,'pagedown') )
        time = Figures.time + 5;
        Backtracker.TimeChange(time);
    elseif ( strcmpi(evt.Key,'pageup') )
        time = Figures.time - 5;
        Backtracker.TimeChange(time);
        
    elseif ( strcmpi(evt.Key,'escape') )
        Backtracker.SelectTrackingCell([],0);
    end
end

function cellKeyPress(src,evt)
    treeKeyPress(src,evt);

    if ( strcmpi(evt.Key,'delete') || strcmpi(evt.Key,'backspace') )
        uiTrackingEntry()
    end
end

function uiTrackingEntry()
    global Figures
    
    time = Figures.time;
    
    selectedTrackID = Backtracker.GetSelectedTrackID();
    dirFlag = Backtracker.GetSelectedDirTo(time);
    
    if ( selectedTrackID > 0 )
        Backtracker.DeleteTrackingEntry(selectedTrackID, dirFlag, time);
    end
end

function moveTimeLine()
    global Figures HashedCells
    
    curAx = get(Figures.tree.handle, 'CurrentAxes');
    curPoint = get(curAx,'CurrentPoint');
    
    time = round(curPoint(3));

    if(time < 1)
        Figures.time = 1;
    elseif(time > length(HashedCells))
        Figures.time = length(HashedCells);
    else
        Figures.time = time;
    end
    
    Backtracker.UpdateTimeLine();
end

function figureTreeDown(src,evt)
    global Figures
    
    selType = get(Figures.tree.handle, 'SelectionType');
    if ( strcmpi(selType,'normal') )    
        moveTimeLine();
        set(Figures.tree.handle, 'WindowButtonMotionFcn',@figureTreeMotion);
    end
end

function figureTreeUp(src,evt)
    global Figures
    
    selType = get(Figures.tree.handle, 'SelectionType');
    if ( strcmpi(selType,'normal') )  
        set(Figures.tree.handle, 'WindowButtonMotionFcn','');
        Backtracker.TimeChange(Figures.time);
    end
end

function figureTreeMotion(src,evt)
    moveTimeLine();
end

function figureCellsDown(src,evt)
    global Figures
    
    [axesPt figPt] = getCurrentPoint(Figures.cells.handle);
    
    Figures.cells.lastFigPt = figPt;
    Figures.cells.lastAxesPt = axesPt;
    
    curAx = get(Figures.cells.handle,'CurrentAxes');
    
    if ( Helper.ValidUIHandle(Figures.cells.dragLine) )
        delete(Figures.cells.dragLine);
    end
    
    selType = get(Figures.cells.handle, 'SelectionType');
    if ( strcmpi(selType,'normal') )
        Figures.cells.dragLine = line([axesPt(1) axesPt(1)], [axesPt(2) axesPt(2)], 'parent',curAx, 'Color','r');
        set(Figures.cells.handle, 'WindowButtonMotionFcn',@figureCellsMotion);
    end
end

function figureCellsUp(src,evt)
    global Figures
    
    [axesPt figPt] = getCurrentPoint(Figures.cells.handle);
    
    startPt = Figures.cells.lastAxesPt;
    endPt = axesPt;
    
    time = Figures.time;
    
    selType = get(Figures.cells.handle, 'SelectionType');
    if ( strcmpi(selType,'normal') )
        selectedTrackID = Backtracker.GetSelectedTrackID();
        dirFlag = Backtracker.GetSelectedDirTo(time);
        
        pxDragDist = sqrt(sum((figPt - Figures.cells.lastFigPt).^2));
        if ( pxDragDist > 5 )
            Backtracker.CreateMitosis(selectedTrackID, dirFlag, time, startPt,endPt);
        else
            Backtracker.AddToTrackingCell(selectedTrackID, dirFlag, time, endPt);
        end
    elseif ( strcmpi(selType,'alt') )
        findSelectTrackingCell(endPt);
    end
    
    if ( Helper.ValidUIHandle(Figures.cells.dragLine) )
        delete(Figures.cells.dragLine);
        Figures.cells.dragLine = [];
    end
    
    set(Figures.cells.handle, 'WindowButtonMotionFcn','');
end

function figureCellsMotion(src,evt)
    global Figures
    
    [axesPt figPt] = getCurrentPoint(Figures.cells.handle);
    startPt = Figures.cells.lastAxesPt;
    
    if ( ~Helper.ValidUIHandle(Figures.cells.dragLine) )
        Figures.cells.dragLine = [];
        set(Figures.cells.handle, 'WindowButtonMotionFcn','');
        
        return;
    end
    
    set(Figures.cells.dragLine, 'XData',[startPt(1) axesPt(1)], 'YData',[startPt(2) axesPt(2)]);
end

function [axesPt figPt] = getCurrentPoint(hFig)
    curAx = get(hFig, 'CurrentAxes');
    
    curFigPoint = get(hFig, 'CurrentPoint');
    curAxPoint = get(curAx, 'CurrentPoint');
    
    axesPt = curAxPoint(1,1:2);
    figPt = curFigPoint(1:2);
end

function findSelectTrackingCell(clickPt)
    global CONSTANTS Figures HashedCells CellHulls CellFamilies EditFamIdx BackTrackIdx
    
    famTracks = [CellFamilies(EditFamIdx).tracks];
    famTracks = [famTracks BackTrackIdx];
    
    trackIDs = [HashedCells{Figures.time}.trackID];
    bInTracks = ismember(trackIDs, famTracks);
    
    hullID = [];
    chkHulls = [HashedCells{Figures.time}(bInTracks).hullID];
    if ( ~isempty(chkHulls) )
        bInHull = false(1,length(chkHulls));
        for i=1:length(chkHulls)
            bInHull(i) = Hulls.ExpandedHullContains(CellHulls(chkHulls(i)).points, CONSTANTS.clickMargin, clickPt);
        end

        hullID = chkHulls(bInHull);
        
        if ( nnz(bInHull) > 1 )
            chkHulls = chkHulls(bInHull);
            distSq = getHullDistanceSq(chkHulls, chkPoint);
            [minDist minIdx] = min(abs(distSq));

            hullID = chkHulls(minIdx);
        end
    end
    
    if ( ~isempty(hullID) )
        trackID = Hulls.GetTrackID(hullID);
        Backtracker.SelectTrackingCell(trackID, Figures.time);
        
        return;
    end
    
    if ( Figures.time == length(HashedCells) )
        newTrackID = Backtracker.AddToTrackingCell(0, 1, Figures.time, clickPt);
        Backtracker.SelectTrackingCell(newTrackID, Figures.time);
    end
end

%%%%%%%%%%%%%%%%%%%%%%
% File functions

function saveData(filepath)
    global CellFamilies CellHulls CellTracks HashedCells Costs GraphEdits CONSTANTS ConnectedDist CellPhenotypes Log ReplayEditActions FluorData HaveFluor ResegLinks stains stainColors BackSelectHulls
    save(filepath, 'CellFamilies', 'CellHulls', 'CellTracks', 'HashedCells', 'Costs', 'GraphEdits',...
        'CONSTANTS', 'ConnectedDist', 'CellPhenotypes', 'Log', 'ReplayEditActions', 'FluorData',...
        'HaveFluor', 'ResegLinks', 'stains', 'stainColors', 'BackSelectHulls');
end

function saveFile(src,evt)
    global bDirty curSavedFile Figures
    
    if ( isempty(curSavedFile) )
        saveFileAs(src,evt);
        return;
    end
    
    saveData(curSavedFile);
    
    bDirty = false;
    Backtracker.DrawCells();
    Backtracker.DrawTree(Figures.tree.familyID);
end

function saveFileAs(src,evt)
    global bDirty CONSTANTS curSavedFile Figures
    
    curPath = fileparts(CONSTANTS.matFullFile);
    mainPath = fullfile(curPath, [CONSTANTS.datasetName '_LEVER_backtrack.mat']);
    
    [fileName,pathName,filterIndex] = uiputfile(mainPath);
    if ( filterIndex == 0 )
        return;
    end
    
    curSavedFile = fullfile(pathName, fileName);
    saveData(curSavedFile);
    
    bDirty = false;
    Backtracker.DrawCells();
    Backtracker.DrawTree(Figures.tree.familyID);
end

%%%%%%%%%%%%%%%%%%%%%%
% Figure menu and close functions

function closeFigures(src,evt)
    global Figures bDirty
    
    if ( bDirty )
        resp = questdlg('Any unsaved changes will be lost, save now?', 'Unsaved Changes', 'Yes','No','Cancel', 'Yes');
        if ( strcmpi(resp,'Cancel') )
            return;
        end
        
        if ( strcmpi(resp,'Yes') )
            saveFile(src,evt);
        end
    end
    
    delete(figure(Figures.cells.handle));
    delete(figure(Figures.tree.handle));
    clear global
end

function createMenu()
    global Figures
    
    hCommon = [Figures.tree.handle Figures.cells.handle];
    
    for i=1:length(hCommon)
    
        set(hCommon(i), 'Menu','none', 'Toolbar','figure', 'NumberTitle','off');

        fileMenu = uimenu(...
            'Parent',           hCommon(i),...
            'Label',            'File',...
            'HandleVisibility', 'callback');

%         uimenu(...
%             'Parent',           fileMenu,...
%             'Label',            'Open Data',...
%             'HandleVisibility', 'callback', ...
%             'Callback',         @openFile,...
%             'Enable',           'on',...
%             'Accelerator',      'o');

        uimenu(...
            'Parent',           fileMenu,...
            'Label',            'Save',...
            'HandleVisibility', 'callback', ...
            'Callback',         @saveFile,...
            'Enable',           'on',...
            'Accelerator',      's');

        uimenu(...
            'Parent',           fileMenu,...
            'Label',            'Save As...',...
            'HandleVisibility', 'callback', ...
            'Callback',         @saveFileAs);

        uimenu(...
            'Parent',           fileMenu,...
            'Label',            'Quit',...
            'HandleVisibility', 'callback', ...
            'Separator',        'on',...
            'Callback',         @closeFigures);
    end
    
end
