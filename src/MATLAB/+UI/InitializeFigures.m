% InitializeFigures.m - 
% Creates two figures one for the cell image and the other for the family
% tree.
% Figures will have all the menus, button actions, and context menus set up
% here

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

function InitializeFigures()

global Figures CONSTANTS HashedCells

Figures.time = 1;
% Cell count in active clone
Figures.cellCount = 1;
% Which channel to display in DrawCells
Figures.chanIdx = CONSTANTS.primaryChannel;

oldCellsHandle = [];
oldTreeHandle = [];
if(isfield(Figures,'cells') && isfield(Figures.cells,'handle') && ~isempty(Figures.cells.handle))
    oldCellsHandle = Figures.cells.handle;
    oldTreeHandle = Figures.tree.handle;
end

Figures.cells.handle = figure();
Figures.tree.handle = figure();

Figures.cells.selectedHulls = [];
Figures.controlDown = false; %control key is currently down? for selecting cells and fine adjustment

Figures.cells.downHullID = -1;
Figures.downClickPoint = [0 0];

whitebg(Figures.cells.handle,'k');
whitebg(Figures.tree.handle,'w');

Figures.advanceTimerHandle = timer(...
    'TimerFcn',         @UI.Play,...
    'Period',           .05,...
    'ExecutionMode',    'fixedSpacing',...
    'BusyMode',         'drop');

set(Figures.cells.handle,...
    'WindowScrollWheelFcn', @UI.FigureScroll,...
    'KeyPressFcn',          @UI.FigureKeyPress,...
    'Menu',                 'none',...
    'ToolBar',              'figure',...
    'BusyAction',           'cancel',...
    'Interruptible',        'off',...
    'CloseRequestFcn',      @UI.CloseFigure,...
    'NumberTitle',          'off',...
    'Name',                 [Metadata.GetDatasetName() ' Image Data'],...
    'Tag',                  'cells',...
    'ResizeFcn',            @UI.UpdateSegmentationEditsMenu);

addlistener(Figures.cells.handle, 'WindowKeyRelease', @UI.KeyStateRelease);

Figures.cells.showInterior = false;
Figures.cells.editMode = 'normal';
    
Figures.cells.timeLabel = uicontrol(Figures.cells.handle,...
    'Style','text',...
    'Position',[1 0 60 20],...
    'String',['Time: ' num2str(Figures.time)]);

Figures.cells.chanLabel = uicontrol(Figures.cells.handle,...
    'Style','text',...
    'Position',[60 0 60 20],...
    'String',['Channel: ' num2str(Figures.chanIdx)]);

% Missing Cell counter: number of missing cells in current cell frame
Figures.cells.cellCountLabel = uicontrol(Figures.cells.handle,...
    'Style','text',...
    'Position',[60 0 120 20],...
    'String','',...
    'Visible', 'off');

hPan = pan(Figures.cells.handle);
set(hPan,'ActionPostCallback',@forceRedrawCells);

hZoom = zoom(Figures.cells.handle);
set(hZoom,'ActionPostCallback',@forceRedrawCells);

UI.CreateMenuBar(Figures.cells.handle);
UI.CreateContextMenuCells();

set(Figures.tree.handle,...
    'WindowButtonDownFcn',  @UI.FigureTreeDown,...
    'WindowButtonUpFcn',    @UI.FigureTreeUp,...
    'WindowScrollWheelFcn', @UI.FigureScroll,...
    'KeyPressFcn',          @UI.FigureKeyPress,...
    'CloseRequestFcn',      @UI.CloseFigure,...
    'Menu',                 'none',...
    'ToolBar',              'figure',...
    'BusyAction',           'cancel',...
    'Interruptible',        'off',...
    'NumberTitle',          'off',...
    'Name',                 [Metadata.GetDatasetName() ' Lineage'],...
    'Tag',                  'tree');

addlistener(Figures.tree.handle, 'WindowKeyRelease', @UI.KeyStateRelease);

Figures.tree.trackMap = [];
Figures.tree.trackingLine = [];
Figures.tree.trackingLabel = [];
Figures.tree.trackingBacks = [];

UI.CreateMenuBar(Figures.tree.handle);
UI.CreateContextMenuTree();

%initially the first family will be drawn and time will be set to 1
Figures.tree.timeIndicatorLine = [];
Figures.tree.resegIndicators = [];

Figures.tree.timeLabel = uicontrol(Figures.tree.handle,...
    'Style','text',...
    'Position',[1 0 60 20],...
    'String',['Time: ' num2str(Figures.time)]);

% Cell counter: number of active cells in current tree
Figures.tree.cellCountLabel = uicontrol(Figures.tree.handle,...
    'Style','text',...
    'Position',[60 0 120 20],...
    'String',['Cell Count: ' num2str(1)]);

% Cell edits: number of edits to the movie
Figures.tree.cellEditsLabel = uicontrol(Figures.tree.handle,...
    'Style','text',...
    'Position',[180 0 500 20],...
    'String','');

if(~isempty(oldCellsHandle) && ishandle(oldCellsHandle))
    set(oldCellsHandle,'CloseRequestFcn','remove');
    close(oldCellsHandle);
end
if(~isempty(oldTreeHandle) && ishandle(oldTreeHandle))
    set(oldTreeHandle,'CloseRequestFcn','remove');
    close(oldTreeHandle);
end

Figures.cells.learnButton = uicontrol(...
    'Parent',       Figures.cells.handle,...
    'Style',        'pushbutton',...
    'String',       'Learn From Edits',...
    'Visible',      'off',...
   'CallBack',     @learnFromEdits);

Figures.cells.maxEditedFrame = length(HashedCells);

Families.FindLargestTree([],[]);
end

%% Callback Functions

function learnFromEdits(src,evnt)
    global CellFamilies CellTracks SegmentationEdits Figures
    
    currentHull = CellTracks(CellFamilies(Figures.tree.familyID).rootTrackID).hulls(1);
    
    bErr = Editor.ReplayableEditAction(@Editor.LearnFromEdits);
    if ( bErr )
        return;
    end
    
    Error.LogAction('Propagated from segmentation edits',SegmentationEdits.newHulls);
    
    currentTrackID = Hulls.GetTrackID(currentHull);
    currentFamilyID = CellTracks(currentTrackID).familyID;
    
    Figures.tree.familyID = currentFamilyID;
    
    UI.DrawTree(currentFamilyID);
    UI.DrawCells();
end

function forceRedrawCells(src,evnt)
    UI.DrawCells();
end
