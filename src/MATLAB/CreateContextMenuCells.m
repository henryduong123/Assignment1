function CreateContextMenuCells()
%creates the context menu for the figure that displays the image data and
%the subsequent function calls

%--Eric Wait

global Figures

figure(Figures.cells.handle);
Figures.cells.contextMenuHandle = uicontextmenu;

uimenu(Figures.cells.contextMenuHandle,...
    'Label',        'Change Label',...
    'CallBack',     @changeLabel);

uimenu(Figures.cells.contextMenuHandle,...
    'Label',        'Change Parent',...
    'CallBack',     @changeParent);

addHull = uimenu(Figures.cells.contextMenuHandle,...
    'Label',        'Add Hull',...
    'Separator',    'on');

uimenu(addHull,...
    'Label',        'Number of Hulls to add');

uimenu(addHull,...
    'Label',        '1',...
    'Separator',    'on',...
    'CallBack',     @addHull1);

uimenu(addHull,...
    'Label',        '2',...
    'CallBack',     @addHull2);

uimenu(addHull,...
    'Label',        '3',...
    'CallBack',     @addHull3);

uimenu(addHull,...
    'Label',        '4',...
    'CallBack',     @addHull4);

uimenu(addHull,...
    'Label',        'Other',...
    'Separator',    'on',...
    'CallBack',     @addHullOther);

uimenu(Figures.cells.contextMenuHandle,...
    'Label',        'Remove Hull',...
    'CallBack',     @removeHull);

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
global Figures

[hullID trackID] = getClosestCell();
if(isempty(trackID)),return,end

ContextChangeLabel(Figures.time,trackID);
end

function changeParent(src,evnt)
global Figures
[hullID trackID] = getClosestCell();
if(isempty(trackID)),return,end

ContextChangeParent(trackID,Figures.time);
end

function addHull1(src,evnt)
addHull(1);
end

function addHull2(src,evnt)
addHull(2);
end

function addHull3(src,evnt)
addHull(3);
end

function addHull4(src,evnt)
addHull(4);
end

function addHullOther(src,evnt)
num = inputdlg('Enter Number of Hulls to Add','Add Hulls',1,{1});
if(isempty(num)),return,end;
num = str2double(num(1));
addHull(num);
end

function removeHull(src,evnt)
global Figures

[hullID trackID] = getClosestCell();
if(isempty(trackID)),return,end

RemoveHull(hullID);
History('Push');
LogAction(['Removed hull from track ' num2str(trackID)],hullID,[]);
DrawTree(Figures.tree.familyID);
DrawCells();
end

function markDeath(src,evnt)
global Figures CellTracks

[hullID trackID] = getClosestCell();
if(isempty(trackID)),return,end

CellTracks(trackID).timeOfDeath = Figures.time;

%drop children from tree and run ProcessNewborns
if(~isempty(CellTracks(trackID).childrenTracks))
    familyIDs = [];
    for i=1:length(CellTracks(trackID).childrenTracks)
        familyIDs = [familyIDs ...
            RemoveFromTree(CellTracks(CellTracks(trackID).childrenTracks(i)).startTime,...
            CellTracks(trackID).childrenTracks(i),'yes')];
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
global Figures

[hullID trackID] = getClosestCell();
if(isempty(trackID)),return,end

ContextRemoveFromTree(Figures.time,trackID);
end

function properties(src,evnt)
[hullID trackID] = getClosestCell();
if(isempty(trackID)),return,end

ContextProperties(hullID,trackID);
end

%% Helper functions
function addHull(num)
global Figures

[hullID trackID] = getClosestCell();
if(isempty(trackID)),return,end

newTracks = SplitHull(hullID,num+1);%adding one to the number so that the original hull is accounted for

History('Push');
LogAction('Split cell',trackID,[trackID newTracks]);
DrawTree(Figures.tree.familyID);
DrawCells();
end

function [hullID trackID] = getClosestCell()
hullID = FindHull(get(gca,'CurrentPoint'));
if(0>=hullID)
    warndlg('Please click closer to the center of the desired cell','Unknown Cell');
    trackID = [];
    return
end
trackID = GetTrackID(hullID);
end
