function CreateMenuBar(handle)
%This sets up the custom menu bar for the given figure handle

%--Eric Wait

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
    'Parent',           handle,...
    'Label',            '  ',...
    'HandleVisibility', 'callback',...
    'Enable',           'off');

learnEditsMenu = uimenu(...
    'Parent',           handle,...
    'Label',            'Learn From Edits!',...
    'HandleVisibility', 'callback',...
    'Callback',         @learnFromEdits,...
    'Enable',           'off');

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
    'Callback',         @CloseFigure,...
    'Accelerator',      'w');

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
    'Label',            'Export Image',...
    'Separator',        'on',...
    'HandleVisibility', 'callback', ...
    'Callback',         @exportImage,...
    'Visible',          'off');

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
    'Callback',         @GenerateAVI);

uimenu(...
    'Parent',           fileMenu,...
    'Label',            'Export Cell Metrics',...
    'HandleVisibility', 'callback', ...
    'Callback',         @ExportMetrics);

uimenu(...
    'Parent',           fileMenu,...
    'Label',            'Export AITPD data',...
    'HandleVisibility', 'callback', ...
    'Callback',         @ExportAITPD);

uimenu(...
    'Parent',           fileMenu,...
    'Label',            'Export Lineage Tree (new window)',...
    'HandleVisibility', 'callback', ...
    'Callback',         @ExportTree);

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

labelsMenu = uimenu(...
    'Parent',           viewMenu,...
    'Label',            'Show Labels',...
    'HandleVisibility', 'callback',...
    'Callback',         @toggleLabels,...
    'Checked',          'on',...
    'Accelerator',      'l');

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

playMenu = uimenu(...
    'Parent',           viewMenu,...
    'Label',            'Play',...
    'HandleVisibility', 'callback',...
    'Callback',         @TogglePlay,...
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
    'Callback',         @FindLargestTree,...
    'Separator',      'on');

uimenu(...
    'Parent',           viewMenu,...
    'Label',            'Display Tree...',...
    'HandleVisibility', 'callback',...
    'Callback',         @displayTree);

if(strcmp(get(handle,'Tag'),'cells'))
    Figures.cells.menuHandles.saveMenu = saveMenu;
    Figures.cells.menuHandles.undoMenu = undoMenu;
    Figures.cells.menuHandles.redoMenu = redoMenu;
    Figures.cells.menuHandles.labelsMenu = labelsMenu;
    Figures.cells.menuHandles.playMenu = playMenu;
    Figures.cells.menuHandles.siblingsMenu = siblingsMenu;
    Figures.cells.menuHandles.imageMenu = imageMenu;
    Figures.cells.menuHandles.learnEditsMenu = learnEditsMenu;
else
    Figures.tree.menuHandles.saveMenu = saveMenu;
    Figures.tree.menuHandles.undoMenu = undoMenu;
    Figures.tree.menuHandles.redoMenu = redoMenu;
    Figures.tree.menuHandles.labelsMenu = labelsMenu;
    Figures.tree.menuHandles.playMenu = playMenu;
    Figures.tree.menuHandles.siblingsMenu = siblingsMenu;
    Figures.tree.menuHandles.imageMenu = imageMenu;
    Figures.tree.menuHandles.imageMenu = imageMenu;
    Figures.tree.menuHandles.learnEditsMenu = learnEditsMenu;
end
end

%% Callback functions

function openFile(src,evnt)
LEVer();
end

function saveFile(src,evnt)
SaveData(0);
end

function saveFileAs(src,evnt)
SaveDataAs();
end

function exportImage(src,evnt)
ExportImage(src);
end

function printFigure(src,evnt)
printdlg;
end

function makeMovie(src,evnt)

try
    GenerateAVI();
catch errorMessage
    disp(errorMessage);
end

end

function undo(src,evnt)
History('Pop');
end

function redo(src,evnt)
History('Redo');
end

function toggleLabels(src,evnt)
global Figures
if(strcmp(get(Figures.cells.menuHandles.labelsMenu, 'Checked'), 'on'))
    set(Figures.cells.menuHandles.labelsMenu, 'Checked', 'off');
    set(Figures.tree.menuHandles.labelsMenu, 'Checked', 'off');
    DrawCells();
    DrawTree(Figures.tree.familyID);
else
    set(Figures.cells.menuHandles.labelsMenu, 'Checked', 'on');
    set(Figures.tree.menuHandles.labelsMenu, 'Checked', 'on');
    DrawCells();
    DrawTree(Figures.tree.familyID);
end
end

function toggleSiblings(src,evnt)
global Figures
if(strcmp(get(Figures.cells.menuHandles.siblingsMenu, 'Checked'), 'on'))
    set(Figures.cells.menuHandles.siblingsMenu, 'Checked', 'off');
    set(Figures.tree.menuHandles.siblingsMenu, 'Checked', 'off');
    DrawCells();
else
    set(Figures.cells.menuHandles.siblingsMenu, 'Checked', 'on');
    set(Figures.tree.menuHandles.siblingsMenu, 'Checked', 'on');
    DrawCells();
end
end

function toggleImage(src,evnt)
global Figures
if(strcmp(get(Figures.cells.menuHandles.imageMenu, 'Checked'), 'on'))
    set(Figures.cells.menuHandles.imageMenu, 'Checked', 'off');
    set(Figures.tree.menuHandles.imageMenu, 'Checked', 'off');
    DrawCells();
else
    set(Figures.cells.menuHandles.imageMenu, 'Checked', 'on');
    set(Figures.tree.menuHandles.imageMenu, 'Checked', 'on');
    DrawCells();
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
UpdateTimeIndicatorLine();
DrawCells();
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
DrawTree(CellTracks(answer).familyID);
end

function learnFromEdits(src,evnt)
    global CellFamilies SegmentationEdits Figures
    
    if ( isempty(SegmentationEdits) || isempty(SegmentationEdits.changedHulls) || isempty(SegmentationEdits.newHulls) )
        return;
    end
    
    try
        PropagateChanges(SegmentationEdits.changedHulls, SegmentationEdits.newHulls);
        ProcessNewborns(1:length(CellFamilies));
    catch err
        try
            ErrorHandeling(['Propagating segmentation changes -- ' err.message],err.stack);
            return;
        catch err2
            fprintf('%s',err2.message);
            return;
        end
    end
    
    SegmentationEdits.newHulls = [];
    SegmentationEdits.changedHulls = [];
    UpdateSegmentationEditsMenu();
    
    DrawCells();
    DrawTree(Figures.tree.familyID);
    
    History('Push');
    LogAction('Propagated from segmentation edits',SegmentationEdits.newHulls);
end
