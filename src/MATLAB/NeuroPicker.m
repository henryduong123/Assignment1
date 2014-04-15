function NeuroPicker()
    global hFig hEmptyMenu hClickMenu bDirty viewIm finalIm stainIm stainImFluor drawCircleSize defaultStainID datasetPath datasetName stains stainColors bEdited
    
    hFig = [];
    hEmptyMenu = [];
    hClickMenu = [];
    
    viewIm = [];
    finalIm = [];
    stainIm = [];
    stainImFluor = struct('name',{}, 'color',{}, 'image',{}, 'menu',{});
    
    bDirty = false;
    
    [imgFile,imgPath,filterIdx] = uigetfile('*.tif', 'Select last frame image');
    if ( filterIdx == 0 )
        return;
    end
    
    phaseFiles = dir(fullfile(imgPath,'*_Phase.tif'));
    if ( isempty(phaseFiles) )
        loadFl = questdlg('Would you like to load fluorescent stain images?');
        if ( strcmpi(loadFl,'yes') )
            [stainImFile,stainImPath,filterIdx] = uigetfile(fullfile(imgPath,'*_Phase.tif'), 'Select stain phase image');
            if ( filterIdx ~= 0 )
                loadStainImages(fullfile(stainImPath,stainImFile));
            end
        end
    else
        loadStainImages(fullfile(imgPath,phaseFiles(1).name));
    end
    
    lastImgFile = '';
    lastImgFrame = 0;
    
    flist = dir(fullfile(imgPath,'*.tif'));
    for i=1:length(flist)
        imgFilePattern = '(.+)_t(\d+).tif';
        imgFileTokens = regexpi(flist(i).name,imgFilePattern, 'once','tokens');
        if ( isempty(imgFileTokens) )
            continue;
        end
        
        imgFrame = str2double(imgFileTokens{2});
        if ( imgFrame > lastImgFrame )
            lastImgFrame = imgFrame;
            lastImgFile = [imgFileTokens{1} '_t' imgFileTokens{2} '.tif'];
        end
    end
    
    if ( isempty(lastImgFile) )
        msgbox('Unable to identify last frame image in selected folder.');
        return;
    end
    
    imgFile = lastImgFile;
    
    [sigDigits datasetName] = ParseImageName(imgFile);
    datasetPath = fullfile(imgPath,imgFile);
    
    finalIm = imread(datasetPath);
    viewIm = finalIm;
    
    drawCircleSize = 6;
    
    defaultStainID = 2;
    stains = struct('point',{}, 'stainID',{});
    
    if ( isempty(stainIm) )
        stainColors = struct('stain',{'neuron';'not neuron'}, 'color',{[0 0.7 0];[0.7 0 0]});
    else
        stainColors = struct('stain',{}, 'color',{});
        for i=1:length(stainImFluor)
            stainColors = [stainColors; struct('stain',{stainImFluor(i).name}, 'color',{stainImFluor(i).color})];
        end
    end
    
    bEdited = false;
    
    hFig = figure();
    set(hFig, 'CloseRequestFcn',@closeFigure);
    set(hFig, 'WindowScrollWheelFcn',@scrollToggle);
    set(hFig, 'KeyPressFcn',@figureKeyPress);
    
    createMenu();
    createEmptyMenu();
    createClickMenu();
    
    titleStr = [datasetName ' fixed cell frame'];
    set(hFig, 'Name',[titleStr ' - Staining']);
    
    updateFluorescent();
    drawFrame();
end

function drawStains()
    global hFig hClickMenu drawCircleSize defaultStainID stains stainColors
    
    hAx = get(hFig, 'CurrentAxes');
    hold(hAx, 'on');
    for i=1:length(stains)
        x = stains(i).point(1);
        y = stains(i).point(2);
        
        circleColor = stainColors(stains(i).stainID).color;
        
        h = rectangle('Position', [x-drawCircleSize/2 y-drawCircleSize/2 drawCircleSize drawCircleSize], 'Curvature',[1 1], 'EdgeColor',circleColor,'FaceColor',circleColor, 'Parent',hAx);
        set(h, 'uicontextmenu',hClickMenu,  'ButtonDownFcn',@phenoClick, 'UserData',i);
    end
    
    h = plot(hAx, 1,1, '.', 'Color',stainColors(defaultStainID).color, 'Visible','off', 'MarkerSize',32);
%     hLeg = legend(hAx, h, '');
%     set(hLeg, 'Box','off', 'Color','none');

    axis(hAx,'off');
end

function updateFluorescent()
    global fluorIm fluorAlpha stainImFluor
    
    fluorIm = [];
    fluorAlpha = [];
    
    if ( isempty(stainImFluor) )
        return;
    end
    
    drawFlIdx = [];
    for i=1:length(stainImFluor);
        chkDraw = get(stainImFluor(i).menu, 'Checked');
        if ( strcmpi(chkDraw,'off') )
            continue;
        end
        
        drawFlIdx = [drawFlIdx i];
    end
    
    imSize = size(stainImFluor(1).image);
    
    fluorIm = zeros([imSize 3]);
    fluorAlpha = zeros(imSize);
    
    for i=1:length(drawFlIdx)
        curIdx = drawFlIdx(i);
        
        alphaIm = stainImFluor(curIdx).image;
        colorIm = zeros([size(stainImFluor(curIdx).image) 3]);
        for j=1:3
            colorIm(:,:,j) = stainImFluor(curIdx).color(j) * stainImFluor(curIdx).image;
        end
        
        fluorIm = colorIm.*repmat(alphaIm,[1 1 3]) + (fluorIm.*repmat(fluorAlpha,[1 1 3]).*(1 - repmat(alphaIm,[1 1 3])));
        
        newAlpha = alphaIm + (fluorAlpha .* (1-alphaIm));
        
        fluorIm = fluorIm ./ repmat(newAlpha, [1 1 3]);
        fluorAlpha = newAlpha;
    end
end

function drawFluorescent()
    global hFig stainImFluor hEmptyMenu fluorIm fluorAlpha
    
    if ( isempty(stainImFluor) )
        return;
    end
    
    hAx = get(hFig, 'CurrentAxes');
    
    hold(hAx, 'on');
    hIm = imagesc(fluorIm, 'Parent',hAx, 'alphaData',fluorAlpha, 'AlphaDataMapping','none');
    hold(hAx, 'off');
    
    set(hIm, 'ButtonDownFcn',@imageClick);
    set(hIm, 'uicontextmenu',hEmptyMenu);
end

function drawFrame()
    global hFig hEmptyMenu viewIm
    
    hAx = get(hFig, 'CurrentAxes');
    if ( isempty(hAx) )
        hAx = axes('Parent',hFig);
        set(hFig, 'CurrentAxes', hAx);
        
        xl = [1 size(viewIm,2)];
        yl = [1 size(viewIm,1)];
    else
        xl = xlim(hAx);
        yl = ylim(hAx);
    end
    
    colormap(hAx, gray);
    set(hAx,'Position',[.01 .01 .98 .98]);
    
    hold(hAx, 'off');
    hIm = imagesc(viewIm, 'Parent',hAx);
    set(hIm, 'ButtonDownFcn',@imageClick);
    set(hIm, 'uicontextmenu',hEmptyMenu);
    
    drawFluorescent();
    drawStains();
    
    xlim(hAx,xl);
    ylim(hAx,yl);
end

%%%%%%%%%%%%

function createStainPoint(stainID)
    global hFig bDirty clickedPoint stains
    
    bDirty = true;
    
    set(hFig, 'WindowButtonUpFcn','');
    
    stainIdx = findClickedStain(clickedPoint);
    if ( ~isempty(stainIdx) )
        removeStain(stainIdx);
    end
    
    stains = [stains; struct('point',{clickedPoint}, 'stainID',{stainID})];
    
    createClickMenu();
    createEmptyMenu();
    drawFrame();
end

function deleteStaining(src,evt)
    global hFig bDirty clickedPoint
    
    bDirty = true;
    
    set(hFig, 'WindowButtonUpFcn','');
    
    stainIdx = findClickedStain(clickedPoint);
    if ( isempty(stainIdx) )
        return;
    end
    
    removeStain(stainIdx);
    
    createClickMenu();
    createEmptyMenu();
    drawFrame();
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
    global bDirty stainColors
    
    bDirty = true;
    
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
    
    startColor = getRandomColor(vertcat(stainColors.color));
    
    stainColor = uisetcolor(startColor,'New Stain Color');
    
    stainColors = [stainColors; struct('stain',{stainName{1}}, 'color',{stainColor})];
    
    newStainID = length(stainColors);
    remakeDefaultsMenu();
end

function color = getRandomColor(inColors)
    numTries = 300;
    testColors = zeros(numTries,3);
    minColorDist = zeros(numTries,1);
    for i=1:numTries
        testColors(i) = rand(1,3);
        
        colorDists = badColorDist(testColors(i), inColors);
        minColorDist(i) = min(colorDists);
    end
    
    [bestDist bestColorIdx] = max(minColorDist);
    color = testColors(bestColorIdx);
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

function loadStainImages(filePath)
    global stainIm stainImFluor
    
    [phaseImPath,phaseImName] = fileparts(filePath);
    commonToken = regexpi(phaseImName,'(.+)_Phase', 'once','tokens');
    if ( isempty(commonToken) )
        return;
    end
    
    commonName = commonToken{1};
    commonPattern = regexptranslate('escape',commonName);
    
    fileList = dir(fullfile(phaseImPath,[commonName '*.tif']));
    if ( isempty(fileList) )
        return;
    end
    
    phaseIm = imread(filePath);
    if ( ndims(phaseIm) == 3 )
        phaseIm = mean(phaseIm,3);
    end
    
    stainIm = double(phaseIm) / 255.0;
    
    stainImFluor = struct('name',{}, 'color',{}, 'image',{}, 'menu',{});
    for i=1:length(fileList)
        fluorToken = regexpi(fileList(i).name,[commonPattern '_(.+)\.tif'], 'once','tokens');
        if ( isempty(fluorToken) )
            continue;
        end
        
        if ( strcmpi(fluorToken,'Phase') )
            continue;
        end
        
        im = imread(fullfile(phaseImPath,fileList(i).name));
        if ( ndims(im) == 3 )
            bIgnoreBG = ~all(im==0,3);
            hsvIm = rgb2hsv(im);
            
            hueIm = hsvIm(:,:,1);
            satIm = hsvIm(:,:,2);
            valIm = hsvIm(:,:,3);
            
            guessHue = median(hueIm(bIgnoreBG(:)));
            guessSat = median(satIm(bIgnoreBG(:)));
            guessColor = hsv2rgb([guessHue guessSat 1]);
            
            imGray = valIm;
        else
            imGray = double(im) / 255.0;
            guessColor = getRandomColor(zeros(0,3));
        end
        
        stainImFluor = [stainImFluor; struct('name',{fluorToken{1}}, 'color',{guessColor}, 'image',{imGray}, 'menu',{[]})];
    end
end

function saveFile(src,evt)
    global bDirty curSavedFile
    
    if ( isempty(curSavedFile) )
        saveFileAs(src,evt);
        return;
    end
    
    saveStainInfo(curSavedFile);
    
    bDirty = false;
    drawFrame();
end

function saveFileAs(src,evt)
    global bDirty datasetPath datasetName curSavedFile
    
    curPath = fileparts(datasetPath);
    mainPath = fullfile(curPath, '..', [datasetName '_StainInfo.mat']);
    
    [fileName,pathName,filterIndex] = uiputfile(mainPath);
    if ( filterIndex == 0 )
        return;
    end
    
    curSavedFile = fullfile(pathName, fileName);
    saveStainInfo(curSavedFile);
    
    bDirty = false;
    drawFrame();
end

function openFile(src,evt)
    global bDirty datasetName curSavedFile
    
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
    bDirty = false;
    
    remakeDefaultsMenu();
    createClickMenu();
    createEmptyMenu();
    drawFrame();
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

function figureKeyPress(src,evt)
    if ( strcmpi(evt.Key, 'downarrow') || strcmpi(evt.Key, 'rightarrow') )
        scrollToggle();
    elseif ( strcmpi(evt.Key, 'uparrow') || strcmpi(evt.Key, 'leftarrow') )
        scrollToggle();
    end
end

function scrollToggle(src, evt)
    global hFig bDirty viewIm finalIm stainIm datasetName
    
    if ( isempty(stainIm) )
        titleStr = datasetName;
        viewIm = finalIm;
    elseif ( viewIm == finalIm )
        titleStr = [datasetName ' fixed cell frame'];
        viewIm = stainIm;
    else
        titleStr = [datasetName ' last movie frame'];
        viewIm = finalIm;
    end
    
    % Set figure title.
    if ( bDirty )
        set(hFig, 'Name',[titleStr ' - Staining *']);
    else
        set(hFig, 'Name',[titleStr ' - Staining']);
    end
    
    drawFrame();
end

function closeFigure(src, evt)
    global hFig bDirty
    
    if ( bDirty )
        resp = questdlg('Any unsaved changes will be lost, save now?', 'Unsaved Changes', 'Yes','No','Cancel', 'Yes');
        if ( strcmpi(resp,'Cancel') )
            return;
        end
        
        if ( strcmpi(resp,'Yes') )
            saveFile(src,evt);
        end
    end
    
    delete(hFig);
    clear global;
end

%%%%%%%%%%%%

function createMenu()
    global hFig hDefaultMenu hViewMenu
    
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
    
    hViewMenu = uimenu(...
        'Parent',           hFig,...
        'Label',            'View',...
        'HandleVisibility', 'callback');
    
    hDefaultMenu = uimenu(...
        'Parent',           hFig,...
        'Label',            'Left-Click: ...',...
        'HandleVisibility', 'callback');
    
    remakeViewMenu();
    remakeDefaultsMenu();
end

function remakeViewMenu()
    global hViewMenu stainImFluor
    
    childItems = get(hViewMenu, 'children');
    for i=1:length(childItems)
        delete(childItems(i));
    end
    
    if ( isempty(stainImFluor) )
        uimenu('Parent',hViewMenu,...
               'Enable','off',...
               'Checked','off',...
               'Label','No fluorescent images loaded');
        
        return;
    end
    
    for i=1:length(stainImFluor)
        hMenu = uimenu('Parent',hViewMenu,...
                       'Enable','on',...
                       'Checked','on',...
                       'Label',stainImFluor(i).name,...
                       'ForegroundColor',  stainImFluor(i).color,...
                       'Callback',@(src,evt)(toggleFluorescent(i)));
        
        stainImFluor(i).menu = hMenu;
    end
    
    bAllEnable = true(1,length(stainImFluor));
    uimenu('Parent',hViewMenu,...
           'Enable','on',...
           'Checked','off',...
           'Separator','on',...
           'Label','View all',...
           'Callback',@(src,evt)(setAllFluorescent(bAllEnable)));
    
	bAllDisable = false(1,length(stainImFluor));
    uimenu('Parent',hViewMenu,...
           'Enable','on',...
           'Checked','off',...
           'Label','View none',...
           'Callback',@(src,evt)(setAllFluorescent(bAllDisable)));
end

function toggleFluorescent(fluorID)
    global stainImFluor
    
    if ( isempty(fluorID) )
        return;
    end
    
    if ( fluorID <= 0 )
        return;
    end
    
    if ( fluorID > length(stainImFluor) )
        return;
    end
    
    curShow = get(stainImFluor(fluorID).menu, 'Checked');
    if ( strcmpi(curShow,'on') )
        set(stainImFluor(fluorID).menu, 'Checked','off');
    else
        set(stainImFluor(fluorID).menu, 'Checked','on');
    end
    
    updateFluorescent();
    drawFrame();
end

function setAllFluorescent(bEnabled)
    global stainImFluor
    
    for i=1:length(stainImFluor)
        set(stainImFluor(i).menu, 'Checked','off');
        if ( bEnabled(i) )
            set(stainImFluor(i).menu, 'Checked','on');
        end
    end
    
    updateFluorescent();
    drawFrame();
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
    
    drawFrame();
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
        
        uimenu(...
            'Parent',           hMenu,...
            'Label',            stainColors(i).stain,...
            'Separator',        enSep,...
            'ForegroundColor',  stainColors(i).color,...
            'Callback',         @(src,evt)(funcPtr(i)));
    end
end


