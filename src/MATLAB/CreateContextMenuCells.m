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

% uimenu(Figures.cells.contextMenuHandle,...
%     'Label',        'Change Parent',...
%     'CallBack',     @changeParent);

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

% uimenu(Figures.cells.contextMenuHandle,...
%     'Label',        'Remove From Tree',...
%     'CallBack',     @removeFromTree);

uimenu(Figures.cells.contextMenuHandle,...
    'Label',        'Properties',...
    'CallBack',     @properties,...
    'Separator',    'on');
end

%% Callback functions

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
        History('Push');
        try
            newTree = RemoveFromTree(CellTracks(CellTracks(object.UserData).siblingTrack).startTime,...
                CellTracks(object.UserData).siblingTrack,'yes');
        catch errorMessage
            try
                ErrorHandeling(['RemoveFromTree(' num2str(CellTracks(CellTracks(object.UserData).siblingTrack).startTime)...
                    num2str(CellTracks(object.UserData).siblingTrack) ' yes) -- ' errorMessage.message]);
                return
            catch errorMessage2
                fprintf(errorMessage2.message);
                return
            end
        end
    case num2str(CellTracks(object.UserData).siblingTrack)
        remove = object.UserData;
        History('Push');
        try
            newTree = RemoveFromTree(CellTracks(object.UserData).startTime,object.UserData,'yes');
        catch errorMessage
            try
                ErrorHandeling(['RemoveFromTree(CellTracks(' num2str(CellTracks(object.UserData).startTime) ' '...
                    num2str(object.UserData) ' yes) -- ' errorMessage.message]);
                return
            catch errorMessage2
                fprintf(errorMessage2.message);
                return
            end
        end
    otherwise
        return
end
LogAction(['Removed ' num2str(remove) ' from tree'],Figures.tree.familyID,newTree);
DrawTree(Figures.tree.familyID);
DrawCells();
end

function addMitosis(src,evnt)
global CellTracks Figures HashedCells

[hullID trackID] = GetClosestCell(0);
if(isempty(trackID)),return,end

% answer = inputdlg({['Enter new sibling of ' num2str(trackID)],'Enter Time of Mitosis'},...
%     'Add Mitosis',1,{'',num2str(Figures.time)});

answer = inputdlg({['Enter new sibling of ' num2str(trackID)]},...
    'Add Mitosis',1,{''});

if(isempty(answer)),return,end

siblingTrack = str2double(answer(1));
time = Figures.time;

if(siblingTrack>length(CellTracks) || isempty(CellTracks(siblingTrack).hulls))
    msgbox([answer(1) ' is not a valid cell'],'Not a valid cell','error');
    return
end
if(CellTracks(siblingTrack).endTime<time || siblingTrack==trackID)
    msgbox([answer(1) ' is not a valid sibling'],'Not a valid sibling','error');
    return
end
if(CellTracks(trackID).startTime>time)
    msgbox([num2str(trackID) ' exists after ' answer(1)],'Not a valid child','error');
    return
end
if(~isempty(CellTracks(siblingTrack).timeOfDeath) && CellTracks(siblingTrack).timeOfDeath<=time)
    msgbox(['Cannot attach a cell to cell ' num2str(siblingTrack) ' beacuse it is dead at this time'],'Dead Cell','help');
    return
end
if(~isempty(CellTracks(trackID).timeOfDeath) && CellTracks(trackID).timeOfDeath<=time)
    msgbox(['Cannot attach a cell to cell ' num2str(trackID) ' beacuse it is dead at this time'],'Dead Cell','help');
    return
end

if(CellTracks(trackID).startTime==time && CellTracks(siblingTrack).startTime<time)
    History('Push');
    try
        ChangeTrackParent(siblingTrack,time,trackID);
    catch errorMessage
        try
            ErrorHandeling(['ChangeTrackParent(' num2str(siblingTrack) ' ' num2str(time) ' ' num2str(trackID) ') -- ' errorMessage.message]);
            return
        catch errorMessage2
            fprintf(errorMessage2.message);
            return
        end
    end
    Figures.tree.familyID = CellTracks(siblingTrack).familyID;
elseif(CellTracks(siblingTrack).startTime==time && CellTracks(trackID).startTime<time)
    History('Push');
    try
        ChangeTrackParent(trackID,time,siblingTrack);
    catch errorMessage
        try
            ErrorHandeling(['ChangeTrackParent(' num2str(trackID) ' ' num2str(time) ' ' num2str(siblingTrack) ') -- ' errorMessage.message]);
            return
        catch errorMessage2
            fprintf(errorMessage2.message);
            return
        end
    end
    Figures.tree.familyID = CellTracks(trackID).familyID;
elseif(CellTracks(siblingTrack).startTime==time && CellTracks(trackID).startTime==time)
    valid = 0;
    while(~valid)
        answer = inputdlg({'Enter parent of these siblings '},'Parent',1,{''});
        if(isempty(answer)),return,end
        parentTrack = str2double(answer(1));
        
        if(CellTracks(parentTrack).startTime>=time || isempty(CellTracks(parentTrack).hulls) ||...
                (~isempty(CellTracks(parentTrack).timeOfDeath) && CellTracks(parentTrack).timeOfDeath<=time))
            choice = questdlg([num2str(parentTrack) ' is an invalid parent for these cells, please choose another'],...
                'Not a valid parent','Enter a different parent','Cancel','Cancel');
            switch choice
                case 'Cancel'
                    return
            end
        else
            valid = 1;
        end
    end
    
    History('Push');
    if(~isempty(find([HashedCells{time}.trackID]==parentTrack,1)))
        try
            SwapTrackLabels(time,trackID,parentTrack);
        catch errorMessage
            try
                ErrorHandeling(['SwapTrackLabels(' num2str(time) ' ' num2str(trackID) ' ' num2str(parentTrack) ') -- ' errorMessage.message]);
                return
            catch errorMessage2
                fprintf(errorMessage2.message);
                return
            end
        end
        LogAction('Swapped Labels',trackID,parentTrack);
    else
        try
            ChangeLabel(time,trackID,parentTrack);
        catch errorMessage
            try
                ErrorHandeling(['ChangeLabel(' num2str(time) ' ' num2str(trackID) ' ' num2str(parentTrack) ') -- ' errorMessage.message]);
                return
            catch errorMessage2
                fprintf(errorMessage2.message);
                return
            end
        end
    end
    
    try
        ChangeTrackParent(parentTrack,time,siblingTrack);
    catch errorMessage
        try
            ErrorHandeling(['ChangeTrackParent(' num2str(parentTrack) ' ' num2str(time) ' ' num2str(siblingTrack) ') -- ' errorMessage.message]);
            return
        catch errorMessage2
            fprintf(errorMessage2.message);
            return
        end
    end
    Figures.tree.familyID = CellTracks(parentTrack).familyID;
else
    History('Push');
    try
        ChangeTrackParent(trackID,time,siblingTrack);
    catch errorMessage
        try
            ErrorHandeling(['ChangeTrackParent(' num2str(trackID) ' ' num2str(time) ' ' num2str(siblingTrack) ') -- ' errorMessage.message]);
            return
        catch errorMessage2
            fprintf(errorMessage2.message);
            return
        end
    end
    Figures.tree.familyID = CellTracks(trackID).familyID;
end

LogAction(['Changed parent of ' num2str(trackID) ' and ' num2str(siblingTrack)],[],[]);

DrawTree(Figures.tree.familyID);
DrawCells();
end

function changeLabel(src,evnt)
global Figures

[hullID trackID] = GetClosestCell(0);
if(isempty(trackID)),return,end

ContextChangeLabel(Figures.time,trackID);
end

function changeParent(src,evnt)
global Figures
[hullID trackID] = GetClosestCell(0);
if(isempty(trackID)),return,end

ContextChangeParent(trackID,Figures.time);
end

function addHull1(src,evnt)
AddHull(1);
end

function addHull2(src,evnt)
AddHull(2);
end

function addHull3(src,evnt)
AddHull(3);
end

function addHull4(src,evnt)
AddHull(4);
end

function addHullOther(src,evnt)
num = inputdlg('Enter Number of Hulls to Add','Add Hulls',1,{'1'});
if(isempty(num)),return,end;
num = str2double(num(1));
AddHull(num);
end

function removeHull(src,evnt)
global Figures CellFamilies

[hullID trackID] = GetClosestCell(0);
if(isempty(trackID)),return,end

History('Push');
try
    RemoveHull(hullID);
catch errorMessage
    try
        ErrorHandeling(['RemoveHull(' num2str(hullID) ') -- ' errorMessage.message]);
        return
    catch errorMessage2
        fprintf(errorMessage2.message);
        return
    end
end

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

[hullID trackID] = GetClosestCell(0);
if(isempty(trackID)),return,end

CellTracks(trackID).timeOfDeath = Figures.time;

%drop children from tree and run ProcessNewborns
if(~isempty(CellTracks(trackID).childrenTracks))
    History('Push');
    try
        ProcessNewborns(StraightenTrack(trackID));
    catch errorMessage
        try
            ErrorHandeling(['ProcessNewborns(StraightenTrack(' num2str(trackID) ')-- ' errorMessage.message]);
            return
        catch errorMessage2
            fprintf(errorMessage2.message);
            return
        end
    end
end

LogAction(['Marked time of death for ' num2str(trackID)],[],[]);

DrawTree(Figures.tree.familyID);
DrawCells();
end

function removeFromTree(src,evnt)
global Figures

[hullID trackID] = GetClosestCell(0);
if(isempty(trackID)),return,end

ContextRemoveFromTree(Figures.time,trackID);
end

function properties(src,evnt)
[hullID trackID] = GetClosestCell(0);
if(isempty(trackID)),return,end

ContextProperties(hullID,trackID);
end

%% Helper functions
