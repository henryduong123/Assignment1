%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
%     This file is part of LEVer.exe
%     (C) 2011 Andrew Cohen, Eric Wait and Mark Winter
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function CreateContextMenuCells()
%creates the context menu for the figure that displays the image data and
%the subsequent function calls


global Figures CellPhenotypes CellTracks

if isempty(CellPhenotypes) || ~isfield(CellPhenotypes,'descriptions')
    CellPhenotypes.descriptions={'died'};
    CellPhenotypes.contextMenuID=[];
    CellPhenotypes.hullPhenoSet = zeros(2,0);
end
    
% if ~isfield(CellTracks,'phenotype')
%     CellTracks(1).phenotype=0;
% end

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
    'Label',        'Change Number of Cells',...
    'Separator',    'on');

uimenu(addHull,...
    'Label',        'Number of Cells');

uimenu(addHull,...
    'Label',        '1',...
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
    'Label',        'Remove Cell (this frame)',...
    'CallBack',     @removeHull);

uimenu(Figures.cells.contextMenuHandle,...
    'Label',        'Delete Track',...
    'CallBack',     @removeTrackPrevious);

% uimenu(Figures.cells.contextMenuHandle,...
%     'Label',        'Mark Death',...
%     'CallBack',     @markDeath,...
%     'Separator',    'on');

uimenu(Figures.cells.contextMenuHandle,...
    'Label',        'Remove From Tree',...
    'CallBack',     @removeFromTree);

uimenu(Figures.cells.contextMenuHandle,...
    'Label',        'Properties',...
    'CallBack',     @properties,...
    'Separator',    'on');

PhenoMenu = uimenu(Figures.cells.contextMenuHandle,...
    'Label',        'Phenotype',...
    'Separator',    'on',...
    'CallBack',     @phenoPopulate);

uimenu(PhenoMenu,...
    'Label',        'Create new phenotype...',...
    'CallBack',     @phenotypes);

for i=1:length(CellPhenotypes.descriptions)
    CellPhenotypes.contextMenuID(i)=uimenu(PhenoMenu,...
        'Label',        CellPhenotypes.descriptions{i},...
        'CallBack',     @phenotypes);
end


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
        try
            GraphEditRemoveMitosis(CellTracks(object.UserData).siblingTrack);
            newTree = RemoveFromTree(CellTracks(CellTracks(object.UserData).siblingTrack).startTime,...
                CellTracks(object.UserData).siblingTrack,'yes');
            History('Push');
        catch errorMessage
            try
                ErrorHandeling(['RemoveFromTree(' num2str(CellTracks(CellTracks(object.UserData).siblingTrack).startTime)...
                    num2str(CellTracks(object.UserData).siblingTrack) ' yes) -- ' errorMessage.message],errorMessage.stack);
                return
            catch errorMessage2
                fprintf('%s',errorMessage2.message);
                return
            end
        end
    case num2str(CellTracks(object.UserData).siblingTrack)
        remove = object.UserData;
        try
            GraphEditRemoveMitosis(object.UserData);
            newTree = RemoveFromTree(CellTracks(object.UserData).startTime,object.UserData,'yes');
            History('Push');
        catch errorMessage
            try
                ErrorHandeling(['RemoveFromTree(CellTracks(' num2str(CellTracks(object.UserData).startTime) ' '...
                    num2str(object.UserData) ' yes) -- ' errorMessage.message],errorMessage.stack);
                return
            catch errorMessage2
                fprintf('%s',errorMessage2.message);
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

answer = inputdlg({['Enter new sister of cell' num2str(trackID)]},...
    'Add Mitosis',1,{''});

if(isempty(answer)),return,end

siblingTrack = str2double(answer(1));
time = Figures.time;

if(siblingTrack>length(CellTracks) || isempty(CellTracks(siblingTrack).hulls))
    msgbox([answer(1) ' is not a valid cell'],'Not a valid cell','error');
    return
end
if(CellTracks(siblingTrack).endTime<time || siblingTrack==trackID)
    msgbox([answer(1) ' is not a valid sister cell'],'Not a valid sister cell','error');
    return
end
if(CellTracks(trackID).startTime>time)
    msgbox([num2str(trackID) ' exists after ' answer(1)],'Not a valid daughter cell','error');
    return
end
if(~isempty(GetTimeOfDeath(siblingTrack)) && GetTimeOfDeath(siblingTrack)<=time)
    msgbox(['Cannot attach a cell to cell ' num2str(siblingTrack) ' beacuse it is dead at this time'],'Dead Cell','help');
    return
end
if(~isempty(GetTimeOfDeath(trackID)) && GetTimeOfDeath(trackID)<=time)
    msgbox(['Cannot attach a cell to cell ' num2str(trackID) ' beacuse it is dead at this time'],'Dead Cell','help');
    return
end

if(CellTracks(trackID).startTime==time && CellTracks(siblingTrack).startTime<time)
    try
        GraphEditAddMitosis(time, siblingTrack, trackID);
        ChangeTrackParent(siblingTrack,time,trackID);
        History('Push');
    catch errorMessage
        try
            ErrorHandeling(['ChangeTrackParent(' num2str(siblingTrack) ' ' num2str(time) ' ' num2str(trackID) ') -- ' errorMessage.message],errorMessage.stack);
            return
        catch errorMessage2
            fprintf('%s',errorMessage2.message);
            return
        end
    end
    Figures.tree.familyID = CellTracks(siblingTrack).familyID;
elseif(CellTracks(siblingTrack).startTime==time && CellTracks(trackID).startTime<time)
    try
        GraphEditAddMitosis(time, trackID, siblingTrack);
        ChangeTrackParent(trackID,time,siblingTrack);
        History('Push');
    catch errorMessage
        try
            ErrorHandeling(['ChangeTrackParent(' num2str(trackID) ' ' num2str(time) ' ' num2str(siblingTrack) ') -- ' errorMessage.message],errorMessage.stack);
            return
        catch errorMessage2
            fprintf('%s',errorMessage2.message);
            return
        end
    end
    Figures.tree.familyID = CellTracks(trackID).familyID;
elseif(CellTracks(siblingTrack).startTime==time && CellTracks(trackID).startTime==time)
    valid = 0;
    while(~valid)
        answer = inputdlg({'Enter parent of these daughter cells '},'Parent',1,{''});
        if(isempty(answer)),return,end
        parentTrack = str2double(answer(1));
        
        if(CellTracks(parentTrack).startTime>=time || isempty(CellTracks(parentTrack).hulls) ||...
                (~isempty(GetTimeOfDeath(parentTrack)) && GetTimeOfDeath(parentTrack)<=time))
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
    
    if(~isempty(find([HashedCells{time}.trackID]==parentTrack,1)))
        try
            SwapTrackLabels(time,trackID,parentTrack);
            History('Push');
        catch errorMessage
            try
                ErrorHandeling(['SwapTrackLabels(' num2str(time) ' ' num2str(trackID) ' ' num2str(parentTrack) ') -- ' errorMessage.message],errorMessage.stack);
                return
            catch errorMessage2
                fprintf('%s',errorMessage2.message);
                return
            end
        end
        LogAction('Swapped Labels',trackID,parentTrack);
    else
        try
            ChangeLabel(time,trackID,parentTrack);
        catch errorMessage
            try
                ErrorHandeling(['ChangeLabel(' num2str(time) ' ' num2str(trackID) ' ' num2str(parentTrack) ') -- ' errorMessage.message],errorMessage.stack);
                return
            catch errorMessage2
                fprintf('%s',errorMessage2.message);
                return
            end
        end
    end
    
    try
        GraphEditAddMitosis(time, parentTrack, siblingTrack);
        ChangeTrackParent(parentTrack,time,siblingTrack);
    catch errorMessage
        try
            ErrorHandeling(['ChangeTrackParent(' num2str(parentTrack) ' ' num2str(time) ' ' num2str(siblingTrack) ') -- ' errorMessage.message],errorMessage.stack);
            return
        catch errorMessage2
            fprintf('%s',errorMessage2.message);
            return
        end
    end
    Figures.tree.familyID = CellTracks(parentTrack).familyID;
else
    mitosisTracks = [trackID siblingTrack];
    bCheckParents = (~arrayfun(@(x)(isempty(CellTracks(x).parentTrack)), mitosisTracks));
    [dump,idxLongest] = sort([CellTracks(mitosisTracks).startTime]);
    
    if ( nnz(bCheckParents) == 1 )
        mitosisTracks = [mitosisTracks(bCheckParents) mitosisTracks(~bCheckParents)];
    else
        mitosisTracks = mitosisTracks(idxLongest);
    end
    
    try
        GraphEditAddMitosis(time, mitosisTracks(1), mitosisTracks(2));
        ChangeTrackParent(mitosisTracks(1),time,mitosisTracks(2));
        History('Push');
    catch errorMessage
        try
            ErrorHandeling(['ChangeTrackParent(' num2str(mitosisTracks(1)) ' ' num2str(time) ' ' num2str(mitosisTracks(2)) ') -- ' errorMessage.message],errorMessage.stack);
            return
        catch errorMessage2
            fprintf('%s',errorMessage2.message);
            return
        end
    end
    Figures.tree.familyID = CellTracks(mitosisTracks(1)).familyID;
end

LogAction(['Changed parent of ' num2str(trackID) ' and ' num2str(siblingTrack)]);

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
num = inputdlg('Enter Number of Cells Present','Add Hulls',1,{'1'});
if(isempty(num)),return,end;
num = str2double(num(1));
AddHull(num);
end

function removeHull(src,evnt)
global Figures CellFamilies

[hullID trackID] = GetClosestCell(0);
if(isempty(trackID)),return,end

try
    RemoveHull(hullID);
    History('Push');
catch errorMessage
    try
        ErrorHandeling(['RemoveHull(' num2str(hullID) ') -- ' errorMessage.message],errorMessage.stack);
        return
    catch errorMessage2
        fprintf('%s',errorMessage2.message);
        return
    end
end

LogAction(['Removed hull from track ' num2str(trackID)],hullID);

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
    msgbox(['By removing this cell, the complete tree is no more. Displaying clone rooted at ' num2str(CellFamilies(i).rootTrackID) ' instead'],'Displaying Tree','help');
    return
end

DrawTree(Figures.tree.familyID);
DrawCells();
end

function removeTrackPrevious(src,evnt)
    global Figures CellFamilies

    [hullID trackID] = GetClosestCell(0);
    if(isempty(trackID)),return,end
    
    try
        hullIDs = RemoveTrackPrevious(trackID, hullID);
        if ( isempty(hullIDs) )
            return;
        end
        
        History('Push');
    catch errorMessage
        try
            ErrorHandeling(['RemoveTrackPrevious(' num2str(trackID) ', ' num2str(hullID) ') -- ' errorMessage.message],errorMessage.stack);
            return
        catch errorMessage2
            fprintf('%s',errorMessage2.message);
            return
        end
    end
    LogAction(['Removed hulls from start of track ' num2str(trackID) ' to frame ' num2str(Figures.time)],hullIDs);
    
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
        return
    end

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

% added 4 19 2011 ac
function phenotypes(src,evnt)

global Figures CellPhenotypes CellTracks SegmentationEdits

[hullID trackID] = GetClosestCell(0);
if(isempty(trackID)),return,end
% which did they click
for i=1:length(CellPhenotypes.contextMenuID)
    if src == CellPhenotypes.contextMenuID(i)
        break;
    end
end

if src~=CellPhenotypes.contextMenuID(i)
    % add new one
    NewPhenotype=inputdlg('Enter description for new phenotype','Cell Phenotypes');
    if isempty(NewPhenotype)
        return
    end
    
    PhenoMenu = get(CellPhenotypes.contextMenuID(1),'parent');
    i=length(CellPhenotypes.descriptions)+1;
    CellPhenotypes.contextMenuID(i)=uimenu(PhenoMenu,...
        'Label',        NewPhenotype{1},...
        'CallBack',     @phenotypes);  
    CellPhenotypes.descriptions(i)=NewPhenotype;  

    
end
bActive = strcmp(get(CellPhenotypes.contextMenuID(i),'checked'),'on');

if 1==i
    
	
    if ( bActive )
        % turn off death...
        try
            SetPhenotype(hullID, i, bActive);
            ProcessNewborns(FindFamiliesAfter(trackID), SegmentationEdits.maxEditedFrame);
        catch errorMessage
            try
                ErrorHandeling(['ProcessNewborns(' num2str(trackID) ', ' num2str(SegmentationEdits.maxEditedFrame) ')-- ' errorMessage.message],errorMessage.stack);
                return
            catch errorMessage2
                fprintf('%s',errorMessage2.message);
                return
            end
        end
        LogAction(['Removed death for ' num2str(trackID)],[],[]);
    else
        % turn on death
        if(~isempty(CellTracks(trackID).childrenTracks))
            try
                NewTrackID=StraightenTrack(trackID);
                SetPhenotype(hullID, i, bActive);
                ProcessNewborns(NewTrackID, SegmentationEdits.maxEditedFrame);
            catch errorMessage
                try
                    ErrorHandeling(['ProcessNewborns(StraightenTrack(' num2str(trackID) ',' num2str(SegmentationEdits.maxEditedFrame) ')-- ' errorMessage.message],errorMessage.stack);
                    return
                catch errorMessage2
                    fprintf('%s',errorMessage2.message);
                    return
                end
            end
        end
        LogAction(['Marked time of death for ' num2str(trackID)]);
    end
    History('Push');
    
    DrawCells();
    DrawTree(Figures.tree.familyID);
    return
end

SetPhenotype(hullID, i, bActive);
History('Push');

DrawTree(Figures.tree.familyID);
    
end

% Whenever we right-click on a cell this puts a check mark next to active
% phenotype, if any.
function phenoPopulate(src,evnt)
global CellPhenotypes CellTracks

[hullID trackID] = GetClosestCell(0);
if(isempty(trackID)),return,end
    
for i=1:length(CellPhenotypes.contextMenuID)        
    set(CellPhenotypes.contextMenuID(i),'checked','off');    
end

trackPheno = GetTrackPhenotype(trackID);

if ( trackPheno == 0 )
    return
end
    
set(CellPhenotypes.contextMenuID(trackPheno),'checked','on');
end
%% Helper functions
