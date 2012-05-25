% CreateContextMenuCells.m - creates the context menu for the figure that
% displays the tree data and the subsequent function calls

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

function CreateContextMenuTree()

global Figures

figure(Figures.tree.handle);
Figures.tree.contextMenuHandle = uicontextmenu;

uimenu(Figures.tree.contextMenuHandle,...
    'Label',        'Remove Mitosis',...
    'CallBack',     @removeMitosis);

uimenu(Figures.tree.contextMenuHandle,...
    'Label',        'Add Mitosis',...
    'CallBack',     @addMitosis);

uimenu(Figures.tree.contextMenuHandle,...
    'Label',        'Change Label',...
    'CallBack',     @changeLabel,...
    'Separator',    'on');

uimenu(Figures.tree.contextMenuHandle,...
    'Label',        'Properties',...
    'CallBack',     @properties,...
    'Separator',    'on');
end

%% Callback functions
function removeMitosis(src,evnt)
global CellTracks HashedCells CellFamilies Figures
object = get(gco);
if(strcmp(object.Type,'text') || strcmp(object.Marker,'o'))
    %clicked on a node
    if(isempty(CellTracks(object.UserData).parentTrack))
        msgbox('No Mitosis to Remove','Unable to Remove Mitosis','error');
        return
    end
    choice = object.UserData;
elseif(object.YData(1)==object.YData(2))
    %clicked on a horizontal line
    choice = questdlg('Which Side to Keep?','Merge With Parent',...
        num2str(CellTracks(object.UserData).childrenTracks(1)),...
        num2str(CellTracks(object.UserData).childrenTracks(2)),'Cancel','Cancel');
    
    if(strcmpi(choice,'Cancel')), return, end
    choice = str2double(choice);
else
    %clicked on a vertical line
    msgbox('Please Click on a Cell Label or the Horizontal Edge to Remove Mitosis','Unable to Remove Mitosis','warn');
    return
end

ContextRemoveFromTree(choice);
end

function addMitosis(src,evnt)
global CellTracks HashedCells CellFamilies
trackID = get(gco,'UserData');
time = get(gca,'CurrentPoint');
time = round(time(1,2));

answer = inputdlg({'Enter Time of Mitosis',['Enter new sister cell of ' num2str(trackID)]},...
    'Add Mitosis',1,{num2str(time),''});

if(isempty(answer)),return,end

time = str2double(answer(1));
siblingTrack = str2double(answer(2));

if(siblingTrack>length(CellTracks) || isempty(CellTracks(siblingTrack).hulls))
    msgbox([answer(2) ' is not a valid cell'],'Not a valid cell','error');
    return
end
if(CellTracks(trackID).startTime>time)
    msgbox([num2str(trackID) ' exists after ' answer(1)],'Not a valid daughter cell','error');
    return
end

oldParent = CellTracks(siblingTrack).parentTrack;

try
    GraphEditAddMitosis(time, trackID, siblingTrack);
    ChangeTrackParent(trackID,time,siblingTrack);
    History('Push');
catch errorMessage
    try
        ErrorHandeling(['ChangeTrackParent(' num2str(trackID) ' ' num2str(time) ' '...
            num2str(siblingTrack) ') -- ' errorMessage.message],errorMessage.stack);
        return
    catch errorMessage2
        fprintf('%s',errorMessage2.message);
        return
    end
end
LogAction(['Changed parent of ' num2str(siblingTrack)],oldParent,trackID);

ProcessNewborns(1:length(CellFamilies),length(HashedCells));

DrawTree(CellTracks(trackID).familyID);
DrawCells();
end

function changeLabel(src,evnt)
global CellTracks
trackID = get(gco,'UserData');
ContextChangeLabel(CellTracks(trackID).startTime,trackID);
end

function changeParent(src,evnt)
global CellTracks
trackID = get(gco,'UserData');
ContextChangeParent(trackID,CellTracks(trackID).startTime);
end

function removeFromTree(src,evnt)
global CellTracks
trackID = get(gco,'UserData');
ContextRemoveFromTree(CellTracks(trackID).startTime,trackID);
end

function properties(src,evnt)
global CellTracks
trackID = get(gco,'UserData');
ContextProperties(CellTracks(trackID).hulls(1),trackID);
end
