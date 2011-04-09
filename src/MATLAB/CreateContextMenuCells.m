function CreateContextMenuCells()
%creates the context menu for the figure that displays the image data and
%the subsequent function calls

%--Eric Wait

global Figures

figure(Figures.cells.handle);
Figures.cells.contextMenuHandle = uicontextmenu;

% Figures.cells.contextMenuLabelHandle = uimenu(Figures.cells.contextMenuHandle,...
%     'Label',        'Click to Show Which Cell Is Selected',...
%     'CallBack',     @cellSelected);

Figures.cells.removeMenu = uimenu(Figures.cells.contextMenuHandle,...
    'Label',        'Remove Mitosis',...
    'CallBack',     @removeMitosis,...
    'Visible',      'off');

uimenu(Figures.cells.contextMenuHandle,...
    'Label',        'Add Mitosis',...
    'CallBack',     @addMitosis);

uimenu(Figures.cells.contextMenuHandle,...
    'Label',        'Change Label',...
    'CallBack',     @changeLabel,...
    'Separator',    'on');

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
% function cellSelected(src,evnt)
% %doesn't work, closes context menu
% global Figures
% [hullID trackID] = getClosestCell();
% 
% if(isempty(trackID))
%     set(Figures.cells.contextMenuLabelHandle,'Label','No Cell Selected, Click Closer');
% else
%     set(Figures.cells.contextMenuLabelHandle,'Label',['Cell: ' num2str(trackID)]);
% end
% end

function removeMitosis(src,evnt)
global CellTracks Figures
object = get(gco);

if(~strcmp(object.Tag,'SiblingRelationship'))
    msgbox('Please click on a Relationship line to remove','Not on line','warn');
    return
end

choice = questdlg('Which Side to Keep?','Merge With Parent',object.UserData,...
    num2str(CellTracks(object.UserData).siblingTrack),'Cancel','Cancel');
switch choice
    case num2str(object.UserData)
        remove = CellTracks(object.UserData).siblingTrack;
        newTree = RemoveFromTree(CellTracks(CellTracks(object.UserData).siblingTrack).startTime,...
            CellTracks(object.UserData).siblingTrack,'yes');
    case num2str(CellTracks(object.UserData).siblingTrack)
        remove = object.UserData;
        newTree = RemoveFromTree(CellTracks(object.UserData).startTime,object.UserData,'yes');
    otherwise
        return
end
History('Push');
LogAction(['Removed ' num2str(remove) ' from tree'],Figures.tree.familyID,newTree);
DrawTree(Figures.tree.familyID);
DrawCells();
end

function addMitosis(src,evnt)
global CellTracks Figures

[hullID trackID] = getClosestCell();
if(isempty(trackID)),return,end

answer = inputdlg({'Enter Time of Mitosis',['Enter new sibling of ' num2str(trackID)]},...
    'Add Mitosis',1,{num2str(Figures.time),''});

if(isempty(answer)),return,end

time = str2double(answer(1));
siblingTrack = str2double(answer(2));

if(isempty(CellTracks(siblingTrack).hulls))
    msgbox([answer(2) ' is not a valid cell'],'Not a valid cell','error');
    return
end
if(CellTracks(trackID).startTime>time)
    msgbox([num2str(trackID) ' exists after ' answer(1)],'Not a valid child','error');
    return
end

oldParent = CellTracks(siblingTrack).parentTrack;

if(CellTracks(trackID).startTime==time)
    ChangeTrackParent(siblingTrack,time,trackID);
else
    ChangeTrackParent(trackID,time,siblingTrack);
end

History('Push');
LogAction(['Changed parent of ' num2str(siblingTrack)],oldParent,trackID);

DrawTree(CellTracks(trackID).familyID);
DrawCells();
end

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
global Figures CellFamilies

[hullID trackID] = getClosestCell();
if(isempty(trackID)),return,end

RemoveHull(hullID);
History('Push');
LogAction(['Removed hull from track ' num2str(trackID)],hullID,[]);

%if the whole family disapears with this change, pick a diffrent family to
%display
if(isempty(CellFamilies(Figures.tree.familyID).tracks))
    for i=1:length(CellFamilies)
        if(~isempty(CellFamilies(i).tracks))
            Figures.tree.familyID = i;
            break
        end
    end
    DrawTree(Figures.tree.familyID);
    DrawCells();
    msgbox(['By removing this hull, the complete tree is no more. Displaying tree rooted at ' num2str(CellFamilies(i).rootTrackID) ' instead'],'Displaying Tree','help');
    return
end

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
