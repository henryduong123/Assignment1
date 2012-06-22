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
Figures.controlDown = 0; %control key is currently down? for selecting cells and fine adjustment
Figures.cells.PostDrawHookOnce = {}; %list of functions to call post DrawCells. Cleared on every draw

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
    'Menu',                 'none',...
    'ToolBar',              'figure',...
    'BusyAction',           'cancel',...
    'Interruptible',        'off',...
    'CloseRequestFcn',      @UI.CloseFigure,...
    'NumberTitle',          'off',...
    'Name',                 [CONSTANTS.datasetName ' Image Data'],...
    'Tag',                  'cells',...
    'ResizeFcn',            @UI.UpdateSegmentationEditsMenu);

addlistener(Figures.cells.handle, 'WindowKeyRelease', @figureKeyRelease);
    Figures.tree.movingMitosis = [];

Figures.cells.showInterior = false;
    
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
    'CloseRequestFcn',      @UI.CloseFigure,...
    'Menu',                 'none',...
    'ToolBar',              'figure',...
    'BusyAction',           'cancel',...
    'Interruptible',        'off',...
    'NumberTitle',          'off',...
    'Name',                 [CONSTANTS.datasetName ' Lineage'],...
    'Tag',                  'tree');

    addlistener(Figures.tree.handle, 'WindowKeyRelease', @figureKeyRelease);
    
%WindowButtonMotionFcn callbacks cause 'CurrentPointer' to be updated
%which is needed for dragging
set(Figures.tree.handle, 'WindowButtonMotionFcn',@(src,evt)(src));
Figures.tree.dragging = [];

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
     if(~Figures.controlDown)
         %prevent this from getting reset when moving the mouse
        Figures.controlDown = get(Figures.tree.axesHandle,'CurrentPoint');
        Figures.controlDown = Figures.controlDown(3);
     end
elseif ( strcmp(evnt.Key,'delete') || strcmp(evnt.Key,'backspace') )
	deleteSelectedCells();
elseif (strcmp(evnt.Key,'f12'))
	Figures.cells.showInterior = ~Figures.cells.showInterior;
	UI.DrawCells();
elseif ( strcmp(evnt.Key,'return') )
    mergeSelectedCells();
end
end

function figureKeyRelease(src,evnt)
    global Figures

        Figures.controlDown = 0;
end

function figureTreeDown(src,evnt)
    global Figures indicatorMotionListener indicatorMouseUpListener;

    indicatorMotionListener = addlistener(Figures.tree.handle, 'WindowMouseMotion', @figureTreeMotion);
    indicatorMouseUpListener = addlistener(Figures.tree.handle, 'WindowMouseRelease', @indicatorMouseUp);
    if(strcmp(get(Figures.tree.handle,'SelectionType'),'normal'))
        moveLine();
    end
end

% NLS - 6/8/12
% this actually returns the tracks that the hulls belong to
% I'll Hopefully refactor DrawCells to allow drawing specific hulls soon
function likelyHulls = FindLowestCostHulls(parentTrackID, time)
global CellTracks HashedCells CellHulls Figures
    parentTrack = CellTracks(parentTrackID);

    fromHullID = Tracks.GetHullID(parentTrack.endTime, parentTrackID);
    potentialHulls = HashedCells{time};
    potentialHulls = [potentialHulls.hullID];

    timeDiff = time - CellHulls(fromHullID).time;
    [paths, costs] = mexDijkstra('matlabExtend', fromHullID, abs(timeDiff)+1, @(startID,endID)((any(endID == potentialHulls))), timeDiff);

    likelyHulls = [];
    if(length(paths) > 1)
        %if cost difference between {1} and {2} is really large, attempt to
        %split?
        likelyHulls = [paths{1}(end), paths{2}(end)];
    elseif (length(paths) == 1)
        likelyHulls = [paths{1}(end)];
    end
    
    if(length(likelyHulls) == 1) %attempt to split
        newHulls = Segmentation.ResegmentHull(CellHulls(likelyHulls(1)), [], 2, 1, 1);
        likelyHulls = [];
        if(isempty(newHulls)),return,end
        hull1 = newHulls(1);
        hull2 = newHulls(2);
        Figures.cells.PostDrawHookOnce{end+1} = @(Ax) (plot(Ax, hull1.points(:,1), hull1.points(:,2), 'Color', [.2 .2 .2], 'LineStyle', '-', 'LineWidth', 1.5));
        Figures.cells.PostDrawHookOnce{end+1} = @(Ax) (plot(Ax, hull2.points(:,1), hull2.points(:,2), 'Color', [.8 .8 .8], 'LineStyle', '-', 'LineWidth', 1.5));
    end
    
    for i=1:length(likelyHulls)
        likelyHulls(i) = Hulls.GetTrackID(likelyHulls(i));
    end
end

% NLS - 6/8/2012 - Created
function mitosisHandleDragging(mitosis)
global Figures CellTracks;

    Y = get(Figures.tree.timeIndicatorLine, 'YData');
    Y = Y(2);

    mitosisHandle = get(mitosis,'UserData');
    %don't allow adjusting a mitosis through other mitoses
    minY = CellTracks(mitosisHandle.trackID).startTime + 1;
    if (Y <= minY)
        return;
    end

    children = CellTracks(mitosisHandle.trackID).childrenTracks;
    Figures.tree.movingMitosis = [children, FindLowestCostHulls(mitosisHandle.trackID, Y)];
    
    %determine how far up/down the user should be allowed to drag a mitosis
    if(isempty(CellTracks(children(1)).childrenTracks))
        if(isempty(CellTracks(children(2)).childrenTracks))
            maxY = Inf;
        else
            maxY = CellTracks(children(1)).endTime - 1;
        end
    elseif(isempty(CellTracks(children(2)).childrenTracks))
        maxY = CellTracks(children(2)).endTime - 1;
    else           
        maxY = min(CellTracks(children(1)).endTime,CellTracks(children(2)).endTime) - 1;
    end
    
    if (Y >= maxY)
        return;
    end

    previousMitosisTime = get(mitosisHandle.hLine, 'YData');
    set(mitosisHandle.hLine, 'YData', [Y Y]);
    set(mitosisHandle.diamondHandle, 'YData', Y+1);
    
    set(mitosisHandle.child1Handles(1), 'YData', Y+1);
    text1 = get(mitosisHandle.child1Handles(2), 'Position');
    text1(2) = Y+1; 
    set(mitosisHandle.child1Handles(2), 'Position', text1);
    
    set(mitosisHandle.child2Handles(1), 'YData', Y+1);  
    text2 = get(mitosisHandle.child2Handles(2), 'Position');
    text2(2) = Y+1;
    set(mitosisHandle.child2Handles(2), 'Position', text2);
end

function indicatorMouseUp(src,evt)
    global indicatorMotionListener indicatorMouseUpListener Figures CellTracks;

    delete(indicatorMotionListener);
    delete(indicatorMouseUpListener);

    if(~isempty(Figures.tree.dragging))
        Y = get(Figures.tree.timeIndicatorLine, 'YData');
        Y = Y(2);

        mitosis = Figures.tree.dragging;
        mitosisHandle = get(mitosis,'UserData');
        children = CellTracks(mitosisHandle.trackID).childrenTracks;

        Figures.tree.movingMitosis = [];
        %TODO: actually commit tree changes
        %GraphEditMoveMitosis(Y, children(1));
        %History('Push');
        %DrawTree(CellTracks(mitosisHandle.trackID).familyID);
        Figures.tree.dragging = [];
    end  
end
 
function figureTreeMotion(src,evnt)
global Figures
    moveLine();
    if(~isempty(Figures.tree.dragging))
        mitosisHandleDragging(Figures.tree.dragging);
    end
    UI.DrawCells();
end

function moveLine()
global Figures HashedCells
time = get(Figures.tree.axesHandle,'CurrentPoint');
time = round(time(3));

if(Figures.controlDown)
    time = round((time - Figures.controlDown)/4 + Figures.controlDown);
end

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
    UI.TimeChange(Figures.time);
end
end

function deleteSelectedCells()
    global Figures CellFamilies
    
    bErr = Editor.ReplayableEditAction(@Editor.DeleteCells, Figures.cells.selectedHulls);
    if ( bErr )
        return;
    end

    Editor.History('Push');
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
    
    [bErr deletedCells replaceCell] = Editor.ReplayableEditAction(@Editor.MergeCells, Figures.cells.selectedHulls);
    if ( bErr )
        return;
    end
    
    if ( isempty(replaceCell) )
        msgbox(['Unable to merge [' num2str(Figures.cells.selectedHulls) '] in this frame'],'Unable to Merge','help','modal');
        return;
    end
    
    Editor.History('Push');
    Error.LogAction('Merged cells', [deletedCells replaceCell], replaceCell);

    UI.DrawTree(Figures.tree.familyID);
    UI.DrawCells();
end


function learnFromEdits(src,evnt)
    global CellFamilies CellTracks SegmentationEdits Figures
    
    currentHull = CellTracks(CellFamilies(Figures.tree.familyID).rootTrackID).hulls(1);
    
    bErr = Editor.ReplayableEditAction(@Editor.LearnFromEdits);
    if ( bErr )
        return;
    end
    
    Editor.History('Push');
    Error.LogAction('Propagated from segmentation edits',SegmentationEdits.newHulls);
    
    currentTrackID = Hulls.GetTrackID(currentHull);
    currentFamilyID = CellTracks(currentTrackID).familyID;
    
    Figures.tree.familyID = currentFamilyID;
    
    UI.DrawTree(currentFamilyID);
    UI.DrawCells();
end

function forceRedrawCells(src,evnt)
    UI.DrawCells();
end
