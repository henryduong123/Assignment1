function CreateContextMenuCells()
%creates the context menu for the figure that displays the image data and
%the subsequent function calls

global Figures

figure(Figures.cells.handle);
Figures.cells.contextMenuHandle = uicontextmenu;

uimenu(Figures.cells.contextMenuHandle,...
    'Label',        'Change Label',...
    'CallBack',     @changeLabel);

uimenu(Figures.cells.contextMenuHandle,...
    'Label',        'Change Parent',...
    'CallBack',     @changeParent);

uimenu(Figures.cells.contextMenuHandle,...
    'Label',        'Add Hull',...
    'CallBack',     @addHull,...
    'Separator',    'on',...
    'Enable',       'off');

uimenu(Figures.cells.contextMenuHandle,...
    'Label',        'Remove Hull',...
    'CallBack',     @removeHull,...
    'Enable',       'off');

uimenu(Figures.cells.contextMenuHandle,...
    'Label',        'Mark Death',...
    'CallBack',     @markDeath,...
    'Separator',    'on');

uimenu(Figures.cells.contextMenuHandle,...
    'Label',        'Remove From Tree',...
    'CallBack',     @removeFromTree);

uimenu(Figures.cells.contextMenuHandle,...
    'Label',        'Properties',...
    'CallBack',     @properties,...
    'Separator',    'on');
end

%% Callback functions
function changeLabel(src,evnt)
global Figures HashedCells

hullID = FindHull(get(gca,'CurrentPoint'));
tempIndex = [HashedCells{Figures.time}.hullID]==hullID;
trackID = HashedCells{Figures.time}(tempIndex).trackID;

ContextChangeLabel(Figures.time,trackID);
end

function changeParent(src,evnt)
global Figures HashedCells

hullID = FindHull(get(gca,'CurrentPoint'));
tempIndex = [HashedCells{Figures.time}.hullID]==hullID;
trackID = HashedCells{Figures.time}(tempIndex).trackID;

ContextChangeParent(trackID);
end

function addHull(src,evnt)
end

function removeHull(src,evnt)
end

function markDeath(src,evnt)
global Figures HashedCells CellTracks

hullID = FindHull(get(gca,'CurrentPoint'));
tempIndex = [HashedCells{Figures.time}.hullID]==hullID;
trackID = HashedCells{Figures.time}(tempIndex).trackID;

CellTracks(trackID).timeOfDeath = Figures.time;

%drop children from tree and run ProcessNewborns
if(~isempty(CellTracks(trackID).childrenTracks))
    familyIDs = [];
    for i=1:length(CellTracks(trackID).childrenTracks)
        familyIDs = [familyIDs ...
            RemoveFromTree(CellTracks(CellTracks(trackID).childrenTracks(i)).startTime,...
            CellTracks(trackID).childrenTracks(i))];
    end
    CellTracks(trackID).childrenTracks = [];
    ProcessNewborns(familyIDs);
end    

History('Push');
LogAction(['Marked time of death for ' num2str(trackID)],[],[]);

DrawTree(Figures.tree.familyID);
DrawCells();
end

function removeFromTree(src,evnt)
global Figures HashedCells

hullID = FindHull(get(gca,'CurrentPoint'));
tempIndex = [HashedCells{Figures.time}.hullID]==hullID;
trackID = HashedCells{Figures.time}(tempIndex).trackID;

ContextRemoveFromTree(Figures.time,trackID);
end

function properties(src,evnt)
global Figures HashedCells

hullID = FindHull(get(gca,'CurrentPoint'));
tempIndex = [HashedCells{Figures.time}.hullID]==hullID;
trackID = HashedCells{Figures.time}(tempIndex).trackID;
ContextProperties(hullID,trackID);
end
