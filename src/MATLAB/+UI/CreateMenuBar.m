
% CreateMenuBar.m - This sets up the custom menu bar for the given figure
% handles

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

function CreateMenuBar(handle)

global Figures

fileMenu = uimenu(...
    'Parent',           handle,...
    'Label',            'File',...
    'HandleVisibility', 'callback');

editMenu = uimenu(...
    'Parent',           handle,...
    'Label',            'Edit',...
    'HandleVisibility', 'callback');

viewMenu = uimenu(...
    'Parent',           handle,...
    'Label',            'View',...
    'HandleVisibility', 'callback');

uimenu(...
    'Parent',           fileMenu,...
    'Label',            'Open',...
    'HandleVisibility', 'callback', ...
    'Callback',         @openFile,...
    'Accelerator',      'o');

uimenu(...
    'Parent',           fileMenu,...
    'Label',            'Close',...
    'HandleVisibility', 'callback', ...
    'Callback',         @UI.CloseFigure,...
    'Accelerator',      'w');

uimenu(...
    'Parent',           fileMenu,...
    'Label',            'Load Stain Info...',...
    'HandleVisibility', 'callback', ...
    'Separator',        'on',...
    'Callback',         @loadStainData);

saveMenu = uimenu(...
    'Parent',           fileMenu,...
    'Label',            'Save',...
    'Separator',        'on',...
    'HandleVisibility', 'callback', ...
    'Callback',         @saveFile,...
    'Enable',           'off',...
    'Accelerator',      's');

uimenu(...
    'Parent',           fileMenu,...
    'Label',            'Save As...',...
    'HandleVisibility', 'callback', ...
    'Callback',         @saveFileAs);

uimenu(...
    'Parent',           fileMenu,...
    'Label',            'Print',...
    'Separator',        'on',...
    'HandleVisibility', 'callback', ...
    'Callback',         @printFigure);

uimenu(...
    'Parent',           fileMenu,...
    'Label',            'Export AVI',...
    'Separator',        'on',...
    'HandleVisibility', 'callback', ...
    'Callback',         @makeMovie);

uimenu(...
    'Parent',           fileMenu,...
    'Label',            'Export Cell Metrics',...
    'HandleVisibility', 'callback', ...
    'Callback',         @UI.ExportMetrics);

uimenu(...
    'Parent',           fileMenu,...
    'Label',            'Export AITPD data',...
    'HandleVisibility', 'callback', ...
    'Callback',         @UI.ExportAITPD);

uimenu(...
    'Parent',           fileMenu,...
    'Label',            'Export Lineage Tree (new window)',...
    'HandleVisibility', 'callback', ...
    'Callback',         @UI.ExportTree);

undoMenu = uimenu(...
    'Parent',           editMenu,...
    'Label',            'Undo',...
    'HandleVisibility', 'callback', ...
    'Callback',         @undo,...
    'Enable',           'off',...
    'Accelerator',      'z');

redoMenu = uimenu(...
    'Parent',           editMenu,...
    'Label',            'Redo',...
    'HandleVisibility', 'callback', ...
    'Callback',         @redo,...
    'Enable',           'off',...
    'Accelerator',      'y');

uimenu(...
    'Parent',           editMenu,...
    'Label',            'Tree-Inference',...
    'HandleVisibility', 'callback', ...
    'Callback',         @treeInference,...
    'Separator',        'on',...
    'Enable',           'on',...
    'Accelerator',      'i');

resegMenu = uimenu(...
    'Parent',           editMenu,...
    'Label',            'Resegment from tree',...
    'HandleVisibility', 'callback', ...
    'Callback',         @resegmentation,...
    'Enable',           'on');

mitosisMenu = uimenu(...
    'Parent',           editMenu,...
    'Label',            'Identify tree mitoses',...
    'HandleVisibility', 'callback', ...
    'Callback',         @mitosisEditor,...
    'Enable',           'on');

lockMenu = uimenu(...
    'Parent',           editMenu,...
    'Label',            'Lock Tree',...
    'HandleVisibility', 'callback', ...
    'Callback',         @toggleTreeLock,...
    'Separator',        'on',...
    'Enable',           'on',...
    'Checked',          'off',...
    'Accelerator',      'u');
    

labelsMenu = uimenu(...
    'Parent',           viewMenu,...
    'Label',            'Show Cell Labels',...
    'HandleVisibility', 'callback',...
    'Callback',         @toggleLabels,...
    'Checked',          'on',...
    'Accelerator',      'l');

treeColorMenu = uimenu(...
    'Parent',           viewMenu,...
    'Label',            'Color Tree',...
    'HandleVisibility', 'callback',...
    'Callback',         @toggleTreeColors,...
    'Checked',          'on');

structOnlyMenu = uimenu(...
    'Parent',           viewMenu,...
    'Label',            'Draw Only Structure (faster)',...
    'HandleVisibility', 'callback',...
    'Callback',         @toggleOnlyStructure,...
    'Checked',          'off');

treeLabelsOn = uimenu(...
    'Parent',           viewMenu,...
    'Label',            'Show Off Tree Labels',...
    'HandleVisibility', 'callback',...
    'Callback',         @toggleTreeLabels,...
    'Checked',          'on');

siblingsMenu = uimenu(...
    'Parent',           viewMenu,...
    'Label',            'Show Sister Cell Relationships',...
    'HandleVisibility', 'callback',...
    'Callback',         @toggleSiblings,...
    'Checked',          'off',...
    'Accelerator',      'b');

imageMenu = uimenu(...
    'Parent',           viewMenu,...
    'Label',            'Show Image',...
    'HandleVisibility', 'callback',...
    'Callback',         @toggleImage,...
    'Checked',          'on',...
    'Accelerator',      'i');

fluorMenu = uimenu(...
    'Parent',           viewMenu,...
    'Label',            'Show Fluorescence',...
    'HandleVisibility', 'callback',...
    'Callback',         @toggleFluor,...
    'Checked',          'on');

resegStatusMenu = uimenu(...
    'Parent',           viewMenu,...
    'Label',            'Show Reseg Status',...
    'HandleVisibility', 'callback',...
    'Callback',         @toggleResegStatus,...
    'Checked',          'off');

missingCellsMenu = uimenu(...
    'Parent',           viewMenu,...
    'Label',            'Show Missing Cells Counter',...
    'HandleVisibility', 'callback',...
    'Callback',         @toggleMissingCells,...
    'Checked',          'off');

playMenu = uimenu(...
    'Parent',           viewMenu,...
    'Label',            'Play',...
    'HandleVisibility', 'callback',...
    'Callback',         @UI.TogglePlay,...
    'Checked',          'off',...
    'Accelerator',      'p');

uimenu(...
    'Parent',           viewMenu,...
    'Label',            'Go to Frame...',...
    'HandleVisibility', 'callback',...
    'Callback',         @timeJump,...
    'Accelerator',      't');

uimenu(...
    'Parent',           viewMenu,...
    'Label',            'Display Largest Tree',...
    'HandleVisibility', 'callback',...
    'Callback',         @Families.FindLargestTree,...
    'Separator',      'on');

uimenu(...
    'Parent',           viewMenu,...
    'Label',            'Display Tree...',...
    'HandleVisibility', 'callback',...
    'Callback',         @displayTree,...
    'Accelerator',      'f');

helpMenu = uimenu(...
    'Parent',           handle,...
    'Label',            'Help',...
    'HandleVisibility', 'callback');
 
aboutMenu = uimenu(...
    'Parent',           helpMenu,...
    'Label',            'About',...
    'HandleVisibility', 'callback', ...
    'Callback',         @UI.about);
 uimenu(...
    'Parent',           helpMenu,...
    'Label',            'Update',...
    'HandleVisibility', 'callback', ...
    'Callback',         @UpdateFile);

if(strcmp(get(handle,'Tag'),'cells'))
    Figures.cells.menuHandles.saveMenu = saveMenu;
    Figures.cells.menuHandles.undoMenu = undoMenu;
    Figures.cells.menuHandles.redoMenu = redoMenu;
    Figures.cells.menuHandles.labelsMenu = labelsMenu;
    Figures.cells.menuHandles.treeLabelsOn = treeLabelsOn;
    Figures.cells.menuHandles.playMenu = playMenu;
    Figures.cells.menuHandles.siblingsMenu = siblingsMenu;
    Figures.cells.menuHandles.imageMenu = imageMenu;
    Figures.cells.menuHandles.fluorMenu = fluorMenu;
    Figures.cells.menuHandles.resegStatusMenu = resegStatusMenu;
    Figures.cells.menuHandles.missingCellsMenu = missingCellsMenu;
    Figures.cells.menuHandles.lockMenu = lockMenu;
    Figures.cells.menuHandles.treeColorMenu = treeColorMenu;
    Figures.cells.menuHandles.structOnlyMenu = structOnlyMenu;
%     Figures.cells.menuHandles.learnEditsMenu = learnEditsMenu;
else
    Figures.tree.menuHandles.saveMenu = saveMenu;
    Figures.tree.menuHandles.undoMenu = undoMenu;
    Figures.tree.menuHandles.redoMenu = redoMenu;
    Figures.tree.menuHandles.labelsMenu = labelsMenu;
    Figures.tree.menuHandles.treeLabelsOn = treeLabelsOn;
    Figures.tree.menuHandles.playMenu = playMenu;
    Figures.tree.menuHandles.siblingsMenu = siblingsMenu;
    Figures.tree.menuHandles.imageMenu = imageMenu;
    Figures.tree.menuHandles.fluorMenu = fluorMenu;
    Figures.tree.menuHandles.resegStatusMenu = resegStatusMenu;
    Figures.tree.menuHandles.missingCellsMenu = missingCellsMenu;
    Figures.tree.menuHandles.lockMenu = lockMenu;
    Figures.tree.menuHandles.treeColorMenu = treeColorMenu;
    Figures.tree.menuHandles.structOnlyMenu = structOnlyMenu;
%     Figures.tree.menuHandles.learnEditsMenu = learnEditsMenu;
end
end

%% Callback functions

function openFile(src,evnt)
    global ReplayEditActions
    if ( Load.OpenData() )
        Editor.ReplayableEditAction(@Editor.InitHistory);
        return
    end
    
    try
        Editor.History('Top');
        
        temp = load(CONSTANTS.matFullFile,'ReplayEditActions');
        ReplayEditActions = temp.ReplayEditActions;
    catch mexcp
    end
end

function [stainID stainDist] = findClosestHullStain(hullID, stainPoints)
    global CellHulls
    
	hullPoints = CellHulls(hullID).points;
    bContainedPt = true(size(stainPoints,1),1);
    
    maxExpand = 15;
    minExpand = -2;
    
    stainID = 0;
    stainDist = Inf;
    
    expDist = maxExpand;
    for expDist=minExpand:maxExpand
        bContainedPt = Hulls.ExpandedHullContains(hullPoints, expDist, stainPoints);
        
        if ( bContainedPt >= 1 )
            break;
        end
        
        expDist = expDist - 1;
    end
    
    if ( nnz(bContainedPt) < 1 )
        return;
    end
    
    stainDist = expDist - minExpand;
    stainID = find(bContainedPt,1,'first');
end

function assignPhenotype(hullID, phenoID, bForceAssign)
    trackID = Hulls.GetTrackID(hullID);
    trackPhenoID = Tracks.GetTrackPhenotype(trackID);
    if ( ~bForceAssign && (trackPhenoID > 0) )
        return;
    end
    
    Editor.ReplayableEditAction(@Editor.ContextSetPhenotype, hullID,phenoID,false);
end

function assignStains()
    global stains stainColors HashedCells CellPhenotypes Figures
    
    if ( isempty(stains) )
        return;
    end
    
    Editor.StartReplayableSubtask('AssignStainPhenotypes');
    
    stainPoints = vertcat(stains.point);
    stainPhenoMap = zeros(length(stainColors),1);
    for i=1:length(stainColors)
        [bErr stainPhenoMap(i)] = Editor.ReplayableEditAction(@Editor.AddPhenotype, stainColors(i).stain);
        if ( bErr )
            Editor.StopReplayableSubtask(Figures.time, 'AssignStainPhenotypes');
            return;
        end
        
        CellPhenotypes.colors(stainPhenoMap(i),:) = stainColors(i).color;
    end
    
    lastHullIDs = [HashedCells{end}.hullID];
    distMat = Inf*ones(length(lastHullIDs),size(stainPoints,1));
    for i=1:length(lastHullIDs)
        [stainPointIdx stainDist] = findClosestHullStain(lastHullIDs(i), stainPoints);
        if ( stainPointIdx <= 0 )
            continue;
        end
        
        distMat(i, stainPointIdx) = stainDist;
    end
    
    [minHullDist bestAssignIdx] = min(distMat,[],1);
    for i=1:length(bestAssignIdx)
        if ( isinf(minHullDist(i)) )
            continue;
        end
        
        hullID = lastHullIDs(bestAssignIdx(i));
        
        stainID = stains(i).stainID;
        assignPhenotype(hullID, stainPhenoMap(stainID), 1);
    end
    
    Load.FixDefaultPhenotypes();
    Editor.StopReplayableSubtask(Figures.time, 'AssignStainPhenotypes');
    
    UI.DrawCells();
end

function loadStainData(src,evt)
    global CONSTANTS stains stainColors
    
    chkDir = '.';
    if ( isfield(CONSTANTS,'matFullFile') && ~isempty(CONSTANTS.matFullFile) )
        chkDir = fileparts(CONSTANTS.matFullFile);
    end
    
    [stainFile stainPath filterIdx] = uigetfile(fullfile(chkDir,'*_StainInfo.mat'), 'Open Staining Data',fullfile(chkDir, [CONSTANTS.datasetName '_StainInfo.mat']));
    if ( filterIdx == 0 )
        return;
    end
    
    S = load(fullfile(stainPath,stainFile));
    if ( ~isfield(S,'stains') )
        return;
    end
    
    stains = S.stains;
    stainColors = S.stainColors;
    
    assignStains();
end

function saveFile(src,evnt)
UI.SaveData(0);
end

function saveFileAs(src,evnt)
UI.SaveDataAs();
end

function printFigure(src,evnt)
printdlg(gcf);
end

function makeMovie(src,evnt)

try
    UI.GenerateAVI();
catch errorMessage
    disp(errorMessage);
end

end

function undo(src,evnt)
    Editor.ReplayableEditAction(@Editor.Undo);
end

function redo(src,evnt)
    Editor.ReplayableEditAction(@Editor.Redo);
end

function toggleLabels(src,evnt)
global Figures
if(strcmp(get(Figures.cells.menuHandles.labelsMenu, 'Checked'), 'on'))
    set(Figures.cells.menuHandles.labelsMenu, 'Checked', 'off');
    set(Figures.tree.menuHandles.labelsMenu, 'Checked', 'off');
    UI.DrawCells();
else
    set(Figures.cells.menuHandles.labelsMenu, 'Checked', 'on');
    set(Figures.tree.menuHandles.labelsMenu, 'Checked', 'on');
    UI.DrawCells();
end
end

function toggleTreeColors(src,evnt)
    global Figures
    if(strcmp(get(Figures.cells.menuHandles.treeColorMenu, 'Checked'), 'on'))
        set(Figures.cells.menuHandles.treeColorMenu, 'Checked', 'off');
        set(Figures.tree.menuHandles.treeColorMenu, 'Checked', 'off');
    else
        set(Figures.cells.menuHandles.treeColorMenu, 'Checked', 'on');
        set(Figures.tree.menuHandles.treeColorMenu, 'Checked', 'on');
    end
    UI.DrawTree(Figures.tree.familyID);
end

function toggleOnlyStructure(src,evnt)
    global Figures
    if(strcmp(get(Figures.cells.menuHandles.structOnlyMenu, 'Checked'), 'on'))
        set(Figures.cells.menuHandles.structOnlyMenu, 'Checked', 'off');
        set(Figures.tree.menuHandles.structOnlyMenu, 'Checked', 'off');
    else
        set(Figures.cells.menuHandles.structOnlyMenu, 'Checked', 'on');
        set(Figures.tree.menuHandles.structOnlyMenu, 'Checked', 'on');
    end
    UI.DrawTree(Figures.tree.familyID);
end

function toggleTreeLabels(src,evnt)
global Figures
if(strcmp(get(Figures.cells.menuHandles.treeLabelsOn, 'Checked'), 'on'))
    set(Figures.cells.menuHandles.treeLabelsOn, 'Checked', 'off');
    set(Figures.tree.menuHandles.treeLabelsOn, 'Checked', 'off');
    UI.DrawCells();
    UI.DrawTree(Figures.tree.familyID);
else
    set(Figures.cells.menuHandles.treeLabelsOn, 'Checked', 'on');
    set(Figures.tree.menuHandles.treeLabelsOn, 'Checked', 'on');
    UI.DrawCells();
    UI.DrawTree(Figures.tree.familyID);
end
end

function toggleSiblings(src,evnt)
global Figures
if(strcmp(get(Figures.cells.menuHandles.siblingsMenu, 'Checked'), 'on'))
    set(Figures.cells.menuHandles.siblingsMenu, 'Checked', 'off');
    set(Figures.tree.menuHandles.siblingsMenu, 'Checked', 'off');
    UI.DrawCells();
else
    set(Figures.cells.menuHandles.siblingsMenu, 'Checked', 'on');
    set(Figures.tree.menuHandles.siblingsMenu, 'Checked', 'on');
    UI.DrawCells();
end
end

function toggleImage(src,evnt)
global Figures
if(strcmp(get(Figures.cells.menuHandles.imageMenu, 'Checked'), 'on'))
    set(Figures.cells.menuHandles.imageMenu, 'Checked', 'off');
    set(Figures.tree.menuHandles.imageMenu, 'Checked', 'off');
    UI.DrawCells();
else
    set(Figures.cells.menuHandles.imageMenu, 'Checked', 'on');
    set(Figures.tree.menuHandles.imageMenu, 'Checked', 'on');
    UI.DrawCells();
end
end

function toggleFluor(src,evnt)
global Figures
if(strcmp(get(Figures.cells.menuHandles.fluorMenu, 'Checked'), 'on'))
    set(Figures.cells.menuHandles.fluorMenu, 'Checked', 'off');
    set(Figures.tree.menuHandles.fluorMenu, 'Checked', 'off');
    UI.DrawCells();
else
    set(Figures.cells.menuHandles.fluorMenu, 'Checked', 'on');
    set(Figures.tree.menuHandles.fluorMenu, 'Checked', 'on');
    UI.DrawCells();
end
end

function toggleResegStatus(src, evnt)
    global Figures
    menuChecked = get(Figures.cells.menuHandles.resegStatusMenu, 'Checked');
    if ( strcmp(menuChecked, 'on') )
        set(Figures.cells.menuHandles.resegStatusMenu, 'Checked', 'off');
        set(Figures.tree.menuHandles.resegStatusMenu, 'Checked', 'off');
        UI.DrawTree(Figures.tree.familyID);
    else
        set(Figures.cells.menuHandles.resegStatusMenu, 'Checked', 'on');
        set(Figures.tree.menuHandles.resegStatusMenu, 'Checked', 'on');
        UI.DrawTree(Figures.tree.familyID);
    end
end

function toggleMissingCells(src,evnt)
global Figures
if(strcmp(get(Figures.cells.menuHandles.missingCellsMenu, 'Checked'), 'on'))
    set(Figures.cells.menuHandles.missingCellsMenu, 'Checked', 'off');
    set(Figures.tree.menuHandles.missingCellsMenu, 'Checked', 'off');
    UI.DrawCells();
else
    set(Figures.cells.menuHandles.missingCellsMenu, 'Checked', 'on');
    set(Figures.tree.menuHandles.missingCellsMenu, 'Checked', 'on');
    UI.DrawCells();
end
end

function timeJump(src,evnt)
global Figures HashedCells
answer = inputdlg('Enter Frame Number:','Jump to Time...',1,{num2str(Figures.time)});

if(isempty(answer)),return,end;
answer = str2double(answer(1));

if(answer < 1)
    Figures.time = 1;
elseif(answer > length(HashedCells))
    Figures.time = length(HashedCells);
else
    Figures.time = answer;
end
UI.UpdateTimeIndicatorLine();
UI.DrawCells();
end

function displayTree(src,evnt)
global CellTracks
answer = inputdlg('Enter Tree Containing Cell:','Display Tree',1);
answer = str2double(answer);

if(isempty(answer)),return,end

if(0>=answer || isempty(CellTracks(answer).hulls))
    msgbox([num2str(answer) ' is not a valid cell'],'Not Valid','error');
    return
end
UI.DrawTree(CellTracks(answer).familyID);
UI.DrawCells();
end

function toggleTreeLock(src, evnt)
    global Figures
    
    Editor.ReplayableEditAction(@Editor.TreeLockAction, Figures.tree.familyID);
    UI.DrawTree(Figures.tree.familyID);
end

function treeInference(src, evt)
    global Figures CellFamilies CellTracks HashedCells
    
    if ( CellFamilies(Figures.tree.familyID).bLocked )
        msgbox('Inference cannot be run on a locked tree.', 'Tree Locked', 'warn');
        return;
    end
    
    currentHull = CellTracks(CellFamilies(Figures.tree.familyID).rootTrackID).hulls(1);
    
    stopText = inputdlg({'Enter inference stop time:'}, 'Stop time', 1, {num2str(length(HashedCells))});
    if ( isempty(stopText) || isempty(stopText{1}) )
        return;
    end
    
    stopTime = str2double(stopText{1});
    if ( stopTime < 2 || stopTime > length(HashedCells) )
        msgbox('Invalid stop time.', 'Invalid time', 'warn');
        return;
    end
    
    bErr = Editor.ReplayableEditAction(@Editor.TreeInference, Figures.tree.familyID, stopTime);
    if ( bErr )
        return;
    end
    
    Error.LogAction('Completed Tree Inference', [],[]);
    
    currentTrackID = Hulls.GetTrackID(currentHull);
    currentFamilyID = CellTracks(currentTrackID).familyID;
    
    Figures.tree.familyID = currentFamilyID;
    
    UI.DrawTree(currentFamilyID);
    UI.DrawCells();
end

function resegmentation(src,evnt)
    UI.ResegmentInterface();
end

function mitosisEditor(src, evnt)
    UI.MitosisEditInterface();
end
% Update Function 
function UpdateFile(src,evnt)
global CONSTANTS
	bUpdated = Load.FixOldFileVersions();

        if ( bUpdated )
            Load.AddConstant('version',softwareVersion,1);
            % Save Data
            % Construct a questdlg with two options 
            prompt = questdlg('There is a new update available! Would you like to save the file?', ... 
                                'Save...', ... 
                                'Yes','No','No'); 
                                % Handle response 
                                switch prompt 
                                case 'Yes' 
                                UI.SaveDataAs();
                                case 'No'
                                Helper.SaveLEVerState(CONSTANTS.matFullFile);
                                    otherwise
                                        warndlg('Success This has been updated');
                                end 	
        else
           warndlg('it is already updated');
        end
        

end

