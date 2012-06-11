% InitializeFigures.m - 
% Creates two figures one for the cell image and the other for the family
% tree.
% Figures will have all the menus, button actions, and context menus set up
% here

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

function InitializeFigures()

global Figures CONSTANTS HashedCells

Figures.time = 1;

oldCellsHandle = [];
oldTreeHandle = [];
if(isfield(Figures,'cells') && isfield(Figures.cells,'handle') && ~isempty(Figures.cells.handle))
    oldCellsHandle = Figures.cells.handle;
    oldTreeHandle = Figures.tree.handle;
end

Figures.cells.handle = figure();
Figures.tree.handle = figure();

Figures.cells.selectedHulls = [];
Figures.cells.selecting = false;

whitebg(Figures.cells.handle,'k');
whitebg(Figures.tree.handle,'w');

Figures.advanceTimerHandle = timer(...
    'TimerFcn',         @play,...
    'Period',           .05,...
    'ExecutionMode',    'fixedSpacing',...
    'BusyMode',         'drop');

set(Figures.cells.handle,...
    'WindowScrollWheelFcn', @figureScroll,...
    'KeyPressFcn',          @figureKeyPress,...
    'KeyReleaseFcn',        @figureKeyRelease,...
    'WindowButtonDownFcn',  @figureCellDown,...
    'Menu',                 'none',...
    'ToolBar',              'figure',...
    'BusyAction',           'cancel',...
    'Interruptible',        'off',...
    'CloseRequestFcn',      @UI.CloseFigure,...
    'NumberTitle',          'off',...
    'Name',                 [CONSTANTS.datasetName ' Image Data'],...
    'Tag',                  'cells',...
    'ResizeFcn',            @UI.UpdateSegmentationEditsMenu);

Figures.cells.timeLabel = uicontrol(Figures.cells.handle,...
    'Style','text',...
    'Position',[1 0 60 20],...
    'String',['Time: ' num2str(Figures.time)]);

hPan = pan(Figures.cells.handle);
set(hPan,'ActionPostCallback',@forceRedrawCells);
hZoom = zoom(Figures.cells.handle);
set(hZoom,'ActionPostCallback',@forceRedrawCells);

UI.CreateMenuBar(Figures.cells.handle);
UI.CreateContextMenuCells();

set(Figures.tree.handle,...
    'WindowButtonDownFcn',  @figureTreeDown,...
    'WindowButtonUpFcn',    @figureTreeUp,...
    'WindowScrollWheelFcn', @figureScroll,...
    'KeyPressFcn',          @figureKeyPress,...
    'KeyReleaseFcn',        @figureKeyRelease,...
    'CloseRequestFcn',      @UI.CloseFigure,...
    'Menu',                 'none',...
    'ToolBar',              'figure',...
    'BusyAction',           'cancel',...
    'Interruptible',        'off',...
    'NumberTitle',          'off',...
    'Name',                 [CONSTANTS.datasetName ' Lineage'],...
    'Tag',                  'tree');

UI.CreateMenuBar(Figures.tree.handle);
UI.CreateContextMenuTree();

%initially the first family will be drawn and time will be set to 1
Figures.tree.timeIndicatorLine = [];

Figures.tree.timeLabel = uicontrol(Figures.tree.handle,...
    'Style','text',...
    'Position',[1 0 60 20],...
    'String',['Time: ' num2str(Figures.time)]);

Families.FindLargestTree([],[]);

if(~isempty(oldCellsHandle) && ishandle(oldCellsHandle))
    set(oldCellsHandle,'CloseRequestFcn','remove');
    close(oldCellsHandle);
end
if(~isempty(oldTreeHandle) && ishandle(oldTreeHandle))
    set(oldTreeHandle,'CloseRequestFcn','remove');
    close(oldTreeHandle);
end

Figures.cells.learnButton = uicontrol(...
    'Parent',       Figures.cells.handle,...
    'Style',        'pushbutton',...
    'String',       'Learn From Edits',...
    'Visible',      'off',...
   'CallBack',     @learnFromEdits);

Figures.cells.maxEditedFrame = length(HashedCells);
end

%% Callback Functions

function figureScroll(src,evnt)
global Figures
time = Figures.time + evnt.VerticalScrollCount;
UI.TimeChange(time);
end

function play(src,event)
global Figures HashedCells
time = Figures.time + 1;
if(time == length(HashedCells))
    time = 1;
end
UI.TimeChange(time);
end

function figureKeyPress(src,evnt)
global Figures

if strcmp(evnt.Key,'downarrow') || strcmp(evnt.Key,'rightarrow')
    time = Figures.time + 1;
    UI.TimeChange(time);
elseif strcmp(evnt.Key,'uparrow') ||strcmp(evnt.Key,'leftarrow')
    time = Figures.time - 1;
    UI.TimeChange(time);
elseif  strcmp(evnt.Key,'pagedown')
    time = Figures.time + 5;
    UI.TimeChange(time);
elseif  strcmp(evnt.Key,'pageup')
    time = Figures.time - 5;
    UI.TimeChange(time);
elseif strcmp(evnt.Key,'space')
    UI.TogglePlay(src,evnt);
elseif ( strcmp(evnt.Key,'control') )
    Figures.cells.selecting = true;
elseif ( strcmp(evnt.Key,'delete') || strcmp(evnt.Key,'backspace') )
    Hulls.DeleteSelectedCells();
elseif ( strcmp(evnt.Key,'return') )
    tryMergeSelectedCells();
end
end

function figureKeyRelease(src,evnt)
    global Figures

    if ( (src == Figures.cells.handle) && strcmp(evnt.Key,'control') )
        Figures.cells.selecting = false;
    end
end

function figureCellDown(src,evnt)
global Figures

currentPoint = get(gca,'CurrentPoint');
Figures.cells.currentHullID = Hulls.FindHull(currentPoint);

if ( (Figures.cells.currentHullID ~= -1) && Figures.cells.selecting )
    UI.ToggleCellSelection(Figures.cells.currentHullID);
    return;
end

if(strcmp(get(Figures.cells.handle,'SelectionType'),'normal'))
    if(strcmp(Figures.advanceTimerHandle.Running,'on'))
        UI.TogglePlay(src,evnt);
    end
    
    if ( ~Figures.cells.selecting )
        UI.ClearCellSelection();
    end
    
    if(Figures.cells.currentHullID == -1)
        return
    end
    set(Figures.cells.handle,'WindowButtonUpFcn',@figureCellUp);
elseif(strcmp(get(Figures.cells.handle,'SelectionType'),'extend'))
    if(Figures.cells.currentHullID == -1)
        Segmentation.AddHull(1);
    else
        Segmentation.AddHull(2);
    end
end
if(strcmp(Figures.advanceTimerHandle.Running,'on'))
    UI.TogglePlay(src,evnt);
end
end

function figureCellUp(src,evnt)
global Figures CellTracks CellFamilies HashedCells

set(Figures.cells.handle,'WindowButtonUpFcn','');
if(Figures.cells.currentHullID == -1)
    return
end

currentHullID = Hulls.FindHull(get(gca,'CurrentPoint'));
previousTrackID = Hulls.GetTrackID(Figures.cells.currentHullID);

if(currentHullID~=Figures.cells.currentHullID)
    try
        Tracker.GraphEditSetEdge(Figures.time,Hulls.GetTrackID(currentHullID),previousTrackID);
        Tracker.GraphEditSetEdge(Figures.time,previousTrackID,Hulls.GetTrackID(currentHullID));
        Tracks.SwapLabels(Hulls.GetTrackID(currentHullID),previousTrackID,Figures.time);
        Editor.History('Push')
    catch errorMessage
        try
            Error.ErrorHandling(['SwapTrackLabels(' num2str(Figures.time) ' ' num2str(Hulls.GetTrackID(currentHullID))...
                ' ' num2str(previousTrackID) ') -- ' errorMessage.message],errorMessage.stack);
            return
        catch errorMessage2
            fprintf('%s\n',errorMessage2.message);
            return
        end
    end
    
    Families.ProcessNewborns();
    previousTrackID = Hulls.GetTrackID(currentHullID);
    
elseif(CellTracks(previousTrackID).familyID==Figures.tree.familyID)
    %no change and the current tree contains the cell clicked on
    UI.ToggleCellSelection(Figures.cells.currentHullID);
    return
end

UI.DrawTree(CellTracks(previousTrackID).familyID);
UI.DrawCells();
UI.ToggleCellSelection(Figures.cells.currentHullID);
end

function figureTreeDown(src,evnt)
global Figures
if(strcmp(get(Figures.tree.handle,'SelectionType'),'normal'))
    set(Figures.tree.handle,'WindowButtonMotionFcn',@figureTreeMotion);
    moveLine();
end
end

function figureTreeMotion(src,evnt)
moveLine();
end

function moveLine()
global Figures HashedCells
time = get(Figures.tree.axesHandle,'CurrentPoint');
time = round(time(3));

if(strcmp(Figures.advanceTimerHandle.Running,'on'))
    UI.TogglePlay([],[]);
end
if(time < 1)
    Figures.time = 1;
elseif(time > length(HashedCells))
    Figures.time = length(HashedCells);
else
    Figures.time = time;
end
% DrawCells();
UI.UpdateTimeIndicatorLine();
end

function figureTreeUp(src,evnt)
global Figures
if(strcmp(get(Figures.tree.handle,'SelectionType'),'normal'))
    set(Figures.tree.handle,'WindowButtonMotionFcn','');
    UI.TimeChange(Figures.time);
end
end

function tryMergeSelectedCells()
    global Figures
    
    try
        set(Figures.tree.handle,'Pointer','watch');
        set(Figures.cells.handle,'Pointer','watch');
        [deleteCells replaceCell] = Segmentation.MergeSplitCells(Figures.cells.selectedHulls);
        if ( isempty(replaceCell) )
            set(Figures.tree.handle,'Pointer','arrow');
            set(Figures.cells.handle,'Pointer','arrow');
            msgbox(['Unable to merge [' num2str(Figures.cells.selectedHulls) '] in this frame'],'Unable to Merge','help','modal');
            return;
        end
        Editor.History('Push');
    catch err
        try
            Error.ErrorHandling(['Merging Selected Cells -- ' err.message], err.stack);
            return;
        catch err2
            fprintf('%s',err2.message);
            return;
        end
    end
    set(Figures.tree.handle,'Pointer','arrow');
    set(Figures.cells.handle,'Pointer','arrow');

    UI.DrawCells();
    UI.DrawTree(Figures.tree.familyID);
    
    Error.LogAction('Merged cells',[deleteCells replaceCell],replaceCell);
    
end

function learnFromEdits(src,evnt)
    global CellFamilies CellTracks HashedCells SegmentationEdits Figures
    
    if ( isempty(SegmentationEdits) || ((isempty(SegmentationEdits.newHulls) || isempty(SegmentationEdits.changedHulls))))
        return;
    end
    
    currentHull = CellTracks(CellFamilies(Figures.tree.familyID).rootTrackID).hulls(1);
    
    try
        Tracks.PropagateChanges(SegmentationEdits.changedHulls, SegmentationEdits.newHulls);
        Families.ProcessNewborns();
    catch err
        try
            Error.ErrorHandling(['Propagating segmentation changes -- ' err.message],err.stack);
            return;
        catch err2
            fprintf('%s',err2.message);
            return;
        end
    end
    
    SegmentationEdits.newHulls = [];
    SegmentationEdits.changedHulls = [];
    
    UI.UpdateSegmentationEditsMenu();
    
%     DrawCells();
%     DrawTree(Figures.tree.familyID);
    
    Helper.RunGarbageCollect(currentHull);
    
    Editor.History('Push');
    Error.LogAction('Propagated from segmentation edits',SegmentationEdits.newHulls);
end

function forceRedrawCells(src,evnt)
    UI.DrawCells();
end
