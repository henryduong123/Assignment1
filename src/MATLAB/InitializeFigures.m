function InitializeFigures()
%Creates two figures one for the cell image and the other for the family
%tree.
%Figures will have all the menus, button actions, and context menus set up
%here

%--Eric Wait

global Figures CONSTANTS

Figures.time = 1;

oldCellsHandle = [];
oldTreeHandle = [];
if(isfield(Figures,'cells') && isfield(Figures.cells,'handle') && ~isempty(Figures.cells.handle))
    oldCellsHandle = Figures.cells.handle;
    oldTreeHandle = Figures.tree.handle;
end

Figures.cells.handle = figure();
Figures.tree.handle = figure();

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
    'CloseRequestFcn',      @CloseFigure,...
    'NumberTitle',          'off',...
    'Name',                 [CONSTANTS.datasetName ' Image Data'],...
    'Tag',                  'cells',...
    'ResizeFcn',            @UpdateSegmentationEditsMenu);

Figures.cells.timeLabel = uicontrol(Figures.cells.handle,...
    'Style','text',...
    'Position',[1 0 60 20],...
    'String',['Time: ' num2str(Figures.time)]);

CreateMenuBar(Figures.cells.handle);
CreateContextMenuCells();

set(Figures.tree.handle,...
    'WindowButtonDownFcn',  @figureTreeDown,...
    'WindowButtonUpFcn',    @figureTreeUp,...
    'WindowScrollWheelFcn', @figureScroll,...
    'KeyPressFcn',          @figureKeyPress,...
    'KeyReleaseFcn',        @figureKeyRelease,...
    'CloseRequestFcn',      @CloseFigure,...
    'Menu',                 'none',...
    'ToolBar',              'figure',...
    'BusyAction',           'cancel',...
    'Interruptible',        'off',...
    'NumberTitle',          'off',...
    'Name',                 [CONSTANTS.datasetName ' Lineage'],...
    'Tag',                  'tree');

CreateMenuBar(Figures.tree.handle);
CreateContextMenuTree();

%initially the first family will be drawn and time will be set to 1
Figures.tree.timeIndicatorLine = [];

Figures.tree.timeLabel = uicontrol(Figures.tree.handle,...
    'Style','text',...
    'Position',[1 0 60 20],...
    'String',['Time: ' num2str(Figures.time)]);

FindLargestTree([],[]);

if(~isempty(oldCellsHandle) && ishandle(oldCellsHandle))
    set(oldCellsHandle,'CloseRequestFcn','remove');
    close(oldCellsHandle);
end
if(~isempty(oldTreeHandle) && ishandle(oldTreeHandle))
    set(oldTreeHandle,'CloseRequestFcn','remove');
    close(oldTreeHandle);
end

% pos = get(Figures.cells.handle,'Position');
% position = [pos(3)-120 pos(4)-30 100 20];
Figures.cells.learnButton = uicontrol(...
    'Parent',       Figures.cells.handle,...
    'Style',        'pushbutton',...
    'String',       'Learn From Edits',...
    'Visible',      'off',...
   'CallBack',     @learnFromEdits);
end

%% Callback Functions

function figureScroll(src,evnt)
global Figures
time = Figures.time + evnt.VerticalScrollCount;
TimeChange(time);
end

function play(src,event)
global Figures HashedCells
time = Figures.time + 1;
if(time == length(HashedCells))
    time = 1;
end
TimeChange(time);
end

function figureKeyPress(src,evnt)
global Figures

if strcmp(evnt.Key,'downarrow') || strcmp(evnt.Key,'rightarrow')
    time = Figures.time + 1;
    TimeChange(time);
elseif strcmp(evnt.Key,'uparrow') ||strcmp(evnt.Key,'leftarrow')
    time = Figures.time - 1;
    TimeChange(time);
elseif  strcmp(evnt.Key,'pagedown')
    time = Figures.time + 5;
    TimeChange(time);
elseif  strcmp(evnt.Key,'pageup')
    time = Figures.time - 5;
    TimeChange(time);
elseif strcmp(evnt.Key,'space')
    TogglePlay(src,evnt);
end
end

function figureKeyRelease(src,evnt)
%for future use
end

function figureCellDown(src,evnt)
global Figures

currentPoint = get(gca,'CurrentPoint');
Figures.cells.currentHullID = FindHull(currentPoint);

if(strcmp(get(Figures.cells.handle,'SelectionType'),'normal'))
    if(strcmp(Figures.advanceTimerHandle.Running,'on'))
        TogglePlay(src,evnt);
    end
    if(Figures.cells.currentHullID == -1)
        return
    end
    set(Figures.cells.handle,'WindowButtonUpFcn',@figureCellUp);
elseif(strcmp(get(Figures.cells.handle,'SelectionType'),'extend'))
    if(Figures.cells.currentHullID == -1)
        AddHull(1);
    else
        AddHull(2);
    end
end
if(strcmp(Figures.advanceTimerHandle.Running,'on'))
    TogglePlay(src,evnt);
end
end

function figureCellUp(src,evnt)
global Figures CellTracks

set(Figures.cells.handle,'WindowButtonUpFcn','');
if(Figures.cells.currentHullID == -1)
    return
end

currentHullID = FindHull(get(gca,'CurrentPoint'));
previousTrackID = GetTrackID(Figures.cells.currentHullID);

if(currentHullID~=Figures.cells.currentHullID)
    try
        SwapTrackLabels(Figures.time,GetTrackID(currentHullID),previousTrackID);
        History('Push')
    catch errorMessage
        try
            ErrorHandeling(['SwapTrackLabels(' num2str(Figures.time) ' ' num2str(GetTrackID(currentHullID))...
                ' ' num2str(previousTrackID) ') -- ' errorMessage.message],errorMessage.stack);
            return
        catch errorMessage2
            fprintf('%s',errorMessage2.message);
            return
        end
    end
elseif(CellTracks(previousTrackID).familyID==Figures.tree.familyID)
    %no change and the current tree contains the cell clicked on
    return
end
DrawTree(CellTracks(previousTrackID).familyID);
DrawCells();
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
    TogglePlay([],[]);
end
if(time < 1)
    Figures.time = 1;
elseif(time > length(HashedCells))
    Figures.time = length(HashedCells);
else
    Figures.time = time;
end
UpdateTimeIndicatorLine();
end

function figureTreeUp(src,evnt)
global Figures
if(strcmp(get(Figures.tree.handle,'SelectionType'),'normal'))
    set(Figures.tree.handle,'WindowButtonMotionFcn','');
    TimeChange(Figures.time);
end
end

function learnFromEdits(src,evnt)
    global CellFamilies SegmentationEdits Figures
    
    if ( isempty(SegmentationEdits) || isempty(SegmentationEdits.changedHulls) || isempty(SegmentationEdits.newHulls) )
        return;
    end
    
    try
        PropagateChanges(SegmentationEdits.changedHulls, SegmentationEdits.newHulls);
        ProcessNewborns(1:length(CellFamilies));
    catch err
        try
            ErrorHandeling(['Propagating segmentation changes -- ' err.message],err.stack);
            return;
        catch err2
            fprintf('%s',err2.message);
            return;
        end
    end
    
    SegmentationEdits.newHulls = [];
    SegmentationEdits.changedHulls = [];
    UpdateSegmentationEditsMenu();
    
    DrawCells();
    DrawTree(Figures.tree.familyID);
    
    History('Push');
    LogAction('Propagated from segmentation edits',SegmentationEdits.newHulls);
end
