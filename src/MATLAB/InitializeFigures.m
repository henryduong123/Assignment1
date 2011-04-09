function InitializeFigures()
%Creates two figures one for the cell image and the other for the family
%tree.
%Figures will have all the menus, button actions, and context menus set up
%here

%--Eric Wait

global Figures CONSTANTS

Figures.time = 1;

Figures.cells.handle = figure();
Figures.tree.handle = figure();

Figures.advanceTimerHandle = timer(...
    'TimerFcn',         @play,...
    'Period',           .1,...
    'ExecutionMode',    'fixedRate',...
    'BusyMode',         'queue');

set(Figures.cells.handle,...
    'WindowScrollWheelFcn', @figureScroll,...
    'KeyPressFcn',          @figureKeyPress,...
    'KeyReleaseFcn',        @figureKeyRelease,...
    'WindowButtonDownFcn',  @figureCellDown,...
    'Menu',                 'none',...
    'ToolBar',              'figure',...
    'CloseRequestFcn',      @CloseFigure,...
    'NumberTitle',          'off',...
    'Name',                 [CONSTANTS.datasetName ' Image Data'],...
    'Tag',                  'cells');

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

DrawTree(1);
figure(Figures.tree.handle);

DrawCells();
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

if(strcmp(get(Figures.cells.handle,'SelectionType'),'normal'))
    if(strcmp(Figures.advanceTimerHandle.Running,'on'))
        TogglePlay(src,evnt);
    end
    currentPoint = get(gca,'CurrentPoint');
    Figures.cells.currentHullID = FindHull(currentPoint);
    if(Figures.cells.currentHullID == -1)
        return
    end
    set(Figures.cells.handle,'WindowButtonUpFcn',@figureCellUp);
end
if(strcmp(Figures.advanceTimerHandle.Running,'on'))
    TogglePlay(src,evnt);
end
end

function figureCellUp(src,evnt)
global Figures HashedCells CellTracks
if(Figures.cells.currentHullID == -1)
    return
end
trackID = [HashedCells{Figures.time}(:).hullID]==Figures.cells.currentHullID;
trackID = HashedCells{Figures.time}(trackID).trackID;
DrawTree(CellTracks(trackID).familyID);
DrawCells();
set(Figures.cells.handle,'WindowButtonUpFcn','');
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
