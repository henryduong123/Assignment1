% CreateContextMenuCells.m - creates the context menu for the figure that
% displays the image data and the subsequent function calls

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

function CreateContextMenuCells()

global Figures

figure(Figures.cells.handle);
Figures.cells.contextMenuHandle = uicontextmenu;

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
    'Label',        'Change Parents',... % will display Swap Parent in the right click menu
    'CallBack',     @changeParent,... % route the code to the changeParent function further down the code
    'Separator',    'on'); % will add separator

addHullMenu = uimenu(Figures.cells.contextMenuHandle,...
    'Label',        'Change Number of Cells',...
    'Separator',    'on');

uimenu(addHullMenu,...
    'Label',        'Number of Cells');

uimenu(addHullMenu,...
    'Label',        '1',...
    'CallBack',     @(src,evt)(addHull(src,evt,1)));

uimenu(addHullMenu,...
    'Label',        '2',...
    'CallBack',     @(src,evt)(addHull(src,evt,2)));

uimenu(addHullMenu,...
    'Label',        '3',...
    'CallBack',     @(src,evt)(addHull(src,evt,3)));

uimenu(addHullMenu,...
    'Label',        '4',...
    'CallBack',     @(src,evt)(addHull(src,evt,4)));

uimenu(addHullMenu,...
    'Label',        'Other',...
    'Separator',    'on',...
    'CallBack',     @(src,evt)(addHull(src,evt,-1)));

uimenu(Figures.cells.contextMenuHandle,...
    'Label',        'Remove Cell (this frame)',...
    'CallBack',     @removeHull);

uimenu(Figures.cells.contextMenuHandle,...
    'Label',        'Remove From Tree',...
    'CallBack',     @removeFromTree);

multiTreeMenu = uimenu(Figures.cells.contextMenuHandle,...
    'Label',        'Multi Tree',...
    'Separator',    'on');

uimenu(multiTreeMenu,...
    'Label',        'Add To Extended Family',...
    'CallBack',     @addToExtendedFamily)

uimenu(multiTreeMenu,...
    'Label',        'Remove From Extended Family',...
    'CallBack',     @removeFromExtendedFamily);

uimenu(multiTreeMenu,...
    'Label',        'Show Extended Family',...
    'CallBack',     @showExtendedFamily);

uimenu(multiTreeMenu,...
    'Label',        'Add All To Extended Family',...
    'CallBack',     @addAllToExtendedFamily);

uimenu(multiTreeMenu,...
    'Label',        'Remove All From Extended Family',...
    'CallBack',     @removeAllFromExtendedFamily);

uimenu(Figures.cells.contextMenuHandle,...
    'Label',        'Properties',...
    'CallBack',     @properties,...
    'Separator',    'on');

UI.CreatePhenotypeMenu();

end

%% Callback functions

function removeMitosis(src,evnt)
%%%not used

end

% ChangeLog:
% EW 6/8/12 rewritten
function addMitosis(src,evnt)
global Figures CellTracks

[hullID siblingTrack] = UI.GetClosestCell(0);
if(isempty(siblingTrack)),return,end

[localLabels, revLocalLabels] = UI.GetLocalTreeLabels(Figures.tree.familyID);
siblingTrackStr  = trackToLocal(localLabels, siblingTrack);

answer = inputdlg({['Add ' siblingTrackStr ' as a sibling to:']},...
    'Add Mitosis',1,{''});

if(isempty(answer)),return,end

% trackID = str2double(answer(1));
trackID = localToTrack(revLocalLabels, answer{1});
time = Figures.time;

Editor.ContextAddMitosis(trackID,siblingTrack,time,localLabels,revLocalLabels);
end

function changeLabel(src,evnt)
global Figures

[hullID trackID] = UI.GetClosestCell(0);
if(isempty(trackID)),return,end

Editor.ContextChangeLabel(Figures.time,trackID);
end

function changeParent(src,evnt)
global Figures
% Will Switch two parents together followed by the children and the rest of
% the tree.
[hullID trackID] = UI.GetClosestCell(0);
if(isempty(trackID)),return,end
Editor.ContextChangeParent(Figures.tree.familyID,Figures.time,trackID);
UI.DrawTree(Figures.tree.familyID);
end

function addHull(src, evt, numhulls)
    if ( numhulls < 0 )
        num = inputdlg('Enter Number of Cells Present','Add Hulls',1,{'1'});
        if(isempty(num)),return,end;
        numhulls = str2double(num{1});
    end
    
    Editor.AddHull(numhulls);
end

function removeHull(src,evnt)
global Figures CellFamilies

[hullID trackID] = UI.GetClosestCell(0);
if(isempty(hullID)),return,end

bErr = Editor.ReplayableEditAction(@Editor.DeleteCells, hullID);
if ( bErr )
    return;
end

Error.LogAction(['Removed selected cells [' num2str(hullID) ']'],hullID);

%if the whole family disapears with this change, pick a diffrent family to
%display
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

function removeTrackPrevious(src,evnt)
    global Figures CellFamilies

    [hullID trackID] = UI.GetClosestCell(0);
    if(isempty(trackID)),return,end
    
    bErr = Editor.ReplayableEditAction(@Editor.RemoveTrackHulls, trackID);
    if ( bErr )
        return;
    end
    
    Error.LogAction(['Removed all hulls from track ' num2str(trackID)],[],[]);
    
    %if the whole family disapears with this change, pick a diffrent family to
    %display
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

function removeFromTree(src,evnt)
    global Figures CellTracks

    [hullID trackID] = UI.GetClosestCell(0);
    if(isempty(trackID)),return,end

    oldParent = CellTracks(trackID).parentTrack;
    
    bLocked = Helper.CheckTreeLocked(trackID);
    if ( bLocked )
        resp = questdlg('This edit will affect the structure of tracks on a locked tree, do you wish to continue?', 'Warning: Locked Tree', 'Continue', 'Cancel', 'Cancel');
        if ( strcmpi(resp,'Cancel') )
            return;
        end
    end

    bErr = Editor.ReplayableEditAction(@Editor.ContextRemoveFromTree, trackID, Figures.time);
    if ( bErr )
        return;
    end
    
    Error.LogAction(['Removed part or all of ' num2str(trackID) ' from tree'],[],trackID);

    UI.DrawTree(CellTracks(oldParent).familyID);
end

function addToExtendedFamily(src,evnt)
    global Figures
    
    hullIDs = Figures.cells.selectedHulls;
    if isempty(hullIDs)
        [hullIDs ~] = UI.GetClosestCell(0);
    end
    if(isempty(hullIDs)),return,end

    Editor.ContextAddToExtendedFamily(hullIDs);
end

function removeFromExtendedFamily(src,evnt)
    [hullID trackID] = UI.GetClosestCell(0);
    if(isempty(trackID)),return,end

    Editor.ContextRemoveFromExtendedFamily(trackID);
end

function showExtendedFamily(src,evnt)
    global CellFamilies CellTracks
    
    [hullID trackID] = UI.GetClosestCell(0);
    if(isempty(trackID)),return,end
    
    familyID = CellTracks(trackID).familyID;
    msgbox({'Extended family:', num2str(CellFamilies(familyID).extFamily)})
end

function addAllToExtendedFamily(src,evnt)
    global Figures
    
    Editor.ContextAddAllToExtendedFamily(Figures.time);
end

function removeAllFromExtendedFamily(src,evnt)
    global Figures

    Editor.ContextRemoveAllFromExtendedFamily();
end

function properties(src,evnt)
    [hullID trackID] = UI.GetClosestCell(0);
    if(isempty(trackID)),return,end
    Editor.ContextProperties(hullID,trackID);
end

function localTrackStr = trackToLocal(localLabels, trackID)
    global Figures
    
    bUseShortLabels = strcmp('on',get(Figures.tree.menuHandles.shortLabelsMenu, 'Checked'));

    if bUseShortLabels && isKey(localLabels, trackID)
        localTrackStr = localLabels(trackID);
    else
        localTrackStr = num2str(trackID);
    end
end

function trackID = localToTrack(revLocalLabels, label)
    global Figures

    bUseShortLabels = strcmp('on',get(Figures.tree.menuHandles.shortLabelsMenu, 'Checked'));

    if bUseShortLabels && isKey(revLocalLabels, label)
        trackID = revLocalLabels(label);
    else
        trackID = str2double(label);
    end
end
