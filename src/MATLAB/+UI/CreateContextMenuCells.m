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
    'Label',        'Delete Track',...
    'CallBack',     @removeTrackPrevious);

uimenu(Figures.cells.contextMenuHandle,...
    'Label',        'Remove From Tree',...
    'CallBack',     @removeFromTree);

uimenu(Figures.cells.contextMenuHandle,...
    'Label',        'Properties',...
    'CallBack',     @properties,...
    'Separator',    'on');

UI.CreatePhenotypeMenu();

if Helper.HaveFluor()
    UI.CreateFluorescenceMenu();
end

end

%% Callback functions

function removeMitosis(src,evnt)
%%%not used

end

% ChangeLog:
% EW 6/8/12 rewritten
function addMitosis(src,evnt)
global Figures

[hullID siblingTrack] = UI.GetClosestCell(0);
if(isempty(siblingTrack)),return,end

answer = inputdlg({['Add ' num2str(siblingTrack) ' as a sibling to:']},...
    'Add Mitosis',1,{''});

if(isempty(answer)),return,end

trackID = str2double(answer(1));
time = Figures.time;

Editor.ContextAddMitosis(trackID,siblingTrack,time);
end

function changeLabel(src,evnt)
global Figures

[hullID trackID] = UI.GetClosestCell(0);
if(isempty(trackID)),return,end

Editor.ContextChangeLabel(Figures.time,trackID);
end

function addHull(src, evt, numhulls)
    if ( numhulls < 0 )
        num = inputdlg('Enter Number of Cells Present','Add Hulls',1,{'1'});
        if(isempty(num)),return,end;
        numhulls = str2double(num);
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

Tracker.UpdateHematoFluor(Figures.time);
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

    Tracker.UpdateHematoFluor(Figures.time);
    UI.DrawTree(Figures.tree.familyID);
    UI.DrawCells();
end

function removeFromTree(src,evnt)
    global Figures CellTracks

    [hullID trackID] = UI.GetClosestCell(0);
    if(isempty(trackID)),return,end

    oldParent = CellTracks(trackID).parentTrack;
    
    bLocked = Helper.CheckLocked(trackID);
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

    Tracker.UpdateHematoFluor(Figures.time);
    UI.DrawTree(CellTracks(oldParent).familyID);
end

function properties(src,evnt)
    [hullID trackID] = UI.GetClosestCell(0);
    if(isempty(trackID)),return,end
    Editor.ContextProperties(hullID,trackID);
end
