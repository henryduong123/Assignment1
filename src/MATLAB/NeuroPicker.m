function NeuroPicker()
    global hFig hEmptyMenu hClickMenu drawCircleSize defaultStainID datasetPath datasetName stains stainColors bEdited
    
    hFig = [];
    hEmptyMenu = [];
    hClickMenu = [];
    
    [imgFile,imgPath,filterIdx] = uigetfile('*.tif', 'Select last frame image');
    if ( filterIdx == 0 )
        return;
    end
    
    [sigDigits datasetName] = ParseImageName(imgFile);
    datasetPath = fullfile(imgPath,imgFile);
    
    drawCircleSize = 6;
    
    defaultStainID = 2;
    stains = struct('point',{}, 'stainID',{});
    stainColors = struct('stain',{'unstained';'neuron';'not neuron'}, 'color',{[0.7 0.5 0];[0 0.8 0];[1 0 0]});
    bEdited = false;
    
    hFig = figure();
    set(hFig, 'CloseRequestFcn',@closeFigure);
    
    createMenu();
    createEmptyMenu();
    createClickMenu();
    
    set(hFig, 'Name',[datasetName ' Staining']);
    
    drawLastFrame();
end

function drawLastFrame()
    global hFig hEmptyMenu hClickMenu datasetPath drawCircleSize stains stainColors
    lastIm = imread(datasetPath);
    
    hAx = get(hFig, 'CurrentAxes');
    if ( isempty(hAx) )
        hAx = axes('Parent',hFig);
        set(hFig, 'CurrentAxes', hAx);
    end
    
    colormap(hAx, gray);
    set(hAx,'Position',[.01 .01 .98 .98]);
    
    hold(hAx, 'off');
    hIm = imagesc(lastIm, 'Parent',hAx);
    set(hIm, 'ButtonDownFcn',@imageClick);
    set(hIm, 'uicontextmenu',hEmptyMenu);
    
    hold(hAx, 'on');
    for i=1:length(stains)
        x = stains(i).point(1);
        y = stains(i).point(2);
        
        circleColor = stainColors(stains(i).stainID).color;
        
        h = rectangle('Position', [x-drawCircleSize/2 y-drawCircleSize/2 drawCircleSize drawCircleSize], 'Curvature',[1 1], 'EdgeColor',circleColor,'FaceColor',circleColor, 'Parent',hAx);
        set(h, 'uicontextmenu',hClickMenu,  'ButtonDownFcn',@phenoClick, 'UserData',i);
    end
    
    axis(hAx,'off');
end

%%%%%%%%%%%%

function createStainPoint(stainID)
    global hFig clickedPoint stains
    
    set(hFig, 'WindowButtonUpFcn','');
    
    stainIdx = findClickedStain(clickedPoint);
    if ( ~isempty(stainIdx) )
        removeStain(stainIdx);
    end
    
    stains = [stains; struct('point',{clickedPoint}, 'stainID',{stainID})];
    
    createClickMenu();
    createEmptyMenu();
    drawLastFrame();
end

function deleteStaining(src,evt)
    global hFig clickedPoint
    
    set(hFig, 'WindowButtonUpFcn','');
    
    stainIdx = findClickedStain(clickedPoint);
    if ( isempty(stainIdx) )
        return;
    end
    
    removeStain(stainIdx);
    
    createClickMenu();
    createEmptyMenu();
    drawLastFrame();
end

function stainIdx = findClickedStain(xyPoint)
    global stains drawCircleSize
    
    stainIdx = [];
    if ( isempty(stains) )
        return;
    end
    
    dists = sum((vertcat(stains.point) - repmat(xyPoint,length(stains),1)).^2,2);
    [minDist stainIdx] = min(dists);
    
    if ( isempty(stainIdx) || sqrt(minDist) > ((drawCircleSize/2)+5) )
        stainIdx = [];
        return;
    end
end

function removeStain(stainIdx)
    global stains
    
    stains = [stains(1:(stainIdx-1),:); stains((stainIdx+1):end,:)];
end

function newDefaultStain(src, evt)
    newStainID = createNewStain();
    
    if ( isempty(newStainID) )
        return;
    end
    
    setDefaultStain(newStainID);
end

function newStain(src, evt)
    newStainID = createNewStain();
    if ( isempty(newStainID) )
        return;
    end
    
    createStainPoint(newStainID);
end

function newStainID = createNewStain()
    global stainColors
    
    newStainID = [];
    
    while ( 1 )
        stainName = inputdlg('Enter the name of the stain: ','New Stain');
        if ( isempty(stainName) || isempty(stainName{1}) )
            return;
        end
        
        if ( any(strcmpi(stainName,{stainColors.stain})) )
            resp = questdlg('Stain already exists, please choose a different name.', 'Error: Stain Exists','Ok','Cancel','Ok');
            if ( strcmpi(resp,'cancel') )
                return;
            end
            
            continue;
        end
        
        break;
    end
    
    minColorDist = 0;
    for i=1:300
        startColor = rand(1,3);
        
        colorDists = badColorDist(startColor, vertcat(stainColors.color));
        minColorDist = min(colorDists);
    end
    
    stainColor = uisetcolor(startColor,'New Stain Color');
    
    stainColors = [stainColors; struct('stain',{stainName{1}}, 'color',{stainColor})];
    
    newStainID = length(stainColors);
    remakeDefaultsMenu();
end

function dists = badColorDist(newColor, colors)
    tryColors = [colors;1 1 1; 0.5 0.5 0.5; 0 0 0];
    hsvColors = rgb2hsv([newColor;tryColors]);
    
    numColors = size(tryColors,1);
    
    hueDist = abs(hsvColors(1,1) - hsvColors(2:end,1));
    satValDist = sum((repmat(hsvColors(1,2:3),numColors,1) - hsvColors(2:end,2:3)).^2, 2);
    
    dists = 4*hueDist + sqrt(satValDist);
end

%%%%%%%%%%%%

function imageClick(src, evt)
    global hFig clickedPoint defaultStainID
    currentPoint = get(gca,'CurrentPoint');
    clickedPoint = currentPoint(1,1:2);
    
    selectionType = get(hFig,'SelectionType');
    if ( strcmp(selectionType,'normal') )
        set(hFig, 'WindowButtonUpFcn',@(src,evt)(createStainPoint(defaultStainID)));
    end
end

function phenoClick(stainIdx, src, evt)
    global hFig hClickMenu clickedPoint
    currentPoint = get(gca,'CurrentPoint');
    clickedPoint = currentPoint(1,1:2);
    
    selectionType = get(hFig,'SelectionType');
    if ( strcmp(selectionType,'normal') )
        set(hFig, 'WindowButtonUpFcn',@deleteStaining);
        return;
    end
    
%     set(hClickMenu, 'Position',clickedPoint, 'Visible','on');
%     drawnow();
end

function stainCallback(src, evt)
    global hClickMenu stains stainColors clickedPoint
    
    dists = sum((vertcat(stains.point) - repmat(clickedPoint,length(stains),1)).^2,2);
    [minDist stainIdx] = min(dists);
    
    if ( isempty(stainIdx) )
        return;
    end
    
    stainID = stains(stainIdx).stainID;
    curStain = stainColors(stainID).stain;
    
    childItems = get(hClickMenu, 'children');
    for i=1:length(childItems)
        curLabel = get(childItems(i), 'Label');
        if ( strcmpi(curStain,curLabel) )
            set(childItems(i), 'Checked','on');
        else
            set(childItems(i), 'Checked','off');
        end
    end
end

%%%%%%%%%%%%

function saveStainInfo(filepath)
    global datasetName stains stainColors
    
    save(filepath, 'datasetName', 'stains', 'stainColors');
end

function loadStainInfo(filepath)
    global datasetName stains stainColors
    
    load(filepath);
end

function saveFile(src,evt)
    global curSavedFile
    
    if ( isempty(curSavedFile) )
        saveFileAs(src,evt);
        return;
    end
    
    saveStainInfo(curSavedFile);
end

function saveFileAs(src,evt)
    global datasetPath datasetName curSavedFile
    
    curPath = fileparts(datasetPath);
    mainPath = fullfile(curPath, '..', [datasetName '_StainInfo.mat']);
    
    [fileName,pathName,filterIndex] = uiputfile(mainPath);
    if ( filterIndex == 0 )
        return;
    end
    
    curSavedFile = fullfile(pathName, fileName);
    saveStainInfo(curSavedFile);
end

function openFile(src,evt)
    global datasetName curSavedFile
    
    guessPath = guessOpenPath();
    
    while ( 1 )
        [fileName,pathName,filterIndex] = uigetfile(fullfile(guessPath, '*.mat'));
        if ( filterIndex == 0 )
            return;
        end

        loadFilePath = fullfile(pathName, fileName);
        s = load(loadFilePath);
        
        if ( ~all(isfield(s, {'datasetName' 'stains' 'stainColors'})) )
            resp = questdlg('Error: File selected does not contain stain data', 'Invalid File', 'Ok','Cancel','Ok');
            if ( strcmpi(resp, 'Cancel') )
                return;
            end
            
            continue;
        end
        
        if ( ~strcmpi(s.datasetName,datasetName) )
            resp = questdlg('Warning: File selected does not match the current image data set, load anyway?', 'Dataset Mismatch', 'Yes','No','Cancel','No');
            if ( strcmpi(resp, 'Cancel') )
                return;
            elseif ( strcmpi(resp, 'No') )
                continue;
            end
        end
        
        break;
    end
    
    loadStainInfo(loadFilePath);
    
    curSavedFile = loadFilePath;
    remakeDefaultsMenu();
    createClickMenu();
    createEmptyMenu();
    drawLastFrame();
end

function guessPath = guessOpenPath()
    global datasetPath datasetName curSavedFile
    
    guessPath = '';
    if ( ~isempty(curSavedFile) )
        guessPath = fileparts(curSavedFile);
        return;
    end
    
    curPath = fileparts(datasetPath);
    flist = dir(fullfile(curPath, '*_StainInfo.mat'));
    if ( ~isempty(flist) )
        guessPath = curPath;
        return;
    end
    
    mainPath = fullfile(curPath, '..');
    flist = dir(fullfile(mainPath, '*_StainInfo.mat'));
    if ( ~isempty(flist) )
        guessPath = mainPath;
        return;
    end
end

function closeFigure(src, evt)
    global hFig
    
    delete(hFig);
    clear global;
end

%%%%%%%%%%%%

function createMenu()
    global hFig hDefaultMenu
    
    set(hFig, 'Menu','none', 'Toolbar','figure', 'NumberTitle','off');

    fileMenu = uimenu(...
        'Parent',           hFig,...
        'Label',            'File',...
        'HandleVisibility', 'callback');
    
    uimenu(...
        'Parent',           fileMenu,...
        'Label',            'Open Data',...
        'HandleVisibility', 'callback', ...
        'Callback',         @openFile,...
        'Enable',           'on',...
        'Accelerator',      'o');
    
    uimenu(...
        'Parent',           fileMenu,...
        'Label',            'Save',...
        'HandleVisibility', 'callback', ...
        'Callback',         @saveFile,...
        'Enable',           'on',...
        'Accelerator',      's');

    uimenu(...
        'Parent',           fileMenu,...
        'Label',            'Save As...',...
        'HandleVisibility', 'callback', ...
        'Callback',         @saveFileAs);
    
    uimenu(...
        'Parent',           fileMenu,...
        'Label',            'Quit',...
        'HandleVisibility', 'callback', ...
        'Separator',        'on',...
        'Callback',         @closeFigure);
    
    hDefaultMenu = uimenu(...
        'Parent',           hFig,...
        'Label',            'Left-Click: ...',...
        'HandleVisibility', 'callback');
    
    remakeDefaultsMenu();
end

function remakeDefaultsMenu()
    global hDefaultMenu defaultStainID stainColors
    
    childItems = get(hDefaultMenu, 'children');
    for i=1:length(childItems)
        delete(childItems(i));
    end
    
    addStainMenu(hDefaultMenu, @setDefaultStain);
    
    defaultStainLabel = stainColors(defaultStainID).stain;
    childItems = get(hDefaultMenu, 'children');
    for i=1:length(childItems)
        curLabel = get(childItems(i), 'Label');
        if ( strcmpi(defaultStainLabel,curLabel) )
            set(childItems(i), 'Checked','on');
        else
            set(childItems(i), 'Checked','off');
        end
    end
    
    uimenu(...
        'Parent',           hDefaultMenu,...
        'Label',            'Add Stain...',...
        'Separator',        'on',...
        'Callback',         @newDefaultStain);
    
    defLabel = wrapHTMLBlocks({'Left-Click: '; stainColors(defaultStainID).stain},[0 0 0; stainColors(defaultStainID).color]);
    set(hDefaultMenu,'Label',defLabel);
end

function setDefaultStain(stainID)
    global defaultStainID
    
    defaultStainID = stainID;
    remakeDefaultsMenu();
end

function createClickMenu()
    global hClickMenu stainColors
    
    if ( ~isempty(hClickMenu) )
        delete(hClickMenu);
    end
    hClickMenu = uicontextmenu('Callback',@stainCallback);
    
    addStainMenu(hClickMenu, @createStainPoint);

    uimenu(...
        'Parent',           hClickMenu,...
        'Label',            'Add Stain...',...
        'Separator',        'on',...
        'Callback',         @newStain);
    
    uimenu(...
        'Parent',           hClickMenu,...
        'Label',            'Delete',...
        'Callback',         @deleteStaining);
end

function createEmptyMenu()
    global hEmptyMenu
    
    if ( ~isempty(hEmptyMenu) )
        delete(hEmptyMenu);
    end
    hEmptyMenu = uicontextmenu();
    
    addStainMenu(hEmptyMenu, @createStainPoint);

    uimenu(...
        'Parent',           hEmptyMenu,...
        'Label',            'Add Stain...',...
        'Separator',        'on',...
        'Callback',         @newStain);
end

function htmlLabel = wrapHTMLBlocks(strings,colors)
    htmlLabel = '<HTML>';
    for i=1:length(strings)
        hexColor = '#';
        for j=1:3
            hexColor = [hexColor dec2hex(uint8(255*colors(i,j)), 2)];
        end
        
        htmlLabel = [htmlLabel '<FONT color="' hexColor '">'];
        htmlLabel = [htmlLabel strings{i}];
        htmlLabel = [htmlLabel '</FONT>'];
    end
    
    htmlLabel = [htmlLabel '</HTML>'];
end

function addStainMenu(hMenu, funcPtr)
    global stainColors
    
    for i=1:length(stainColors)
        enSep = 'off';
        if ( i==2 )
            enSep = 'on';
        end
        
        uimenu(...
            'Parent',           hMenu,...
            'Label',            stainColors(i).stain,...
            'Separator',        enSep,...
            'ForegroundColor',  stainColors(i).color,...
            'Callback',         @(src,evt)(funcPtr(i)));
    end
end


