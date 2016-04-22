% Creates a temporary image and segmentation visualization window and
% parameters dialog box for previewing segmentation before running.

function SegPreview()
	hPreviewFig = figure();
    
    Load.SetImageInfo();
    
    hAx = axes('Parent',hPreviewFig, 'Position',[0.01 0.01 0.98 0.98], 'XTick',[],'YTick',[]);
    hTimeLabel = uicontrol(hPreviewFig,'Style','text', 'Position',[1 0 60 20],'String', ['Time: ' num2str(1)]);
    set(hPreviewFig, 'CurrentAxes',hAx);
    
    set(hPreviewFig, 'UserData',struct('time',{1}, 'chan',{1}, 'showInterior',{false}, 'cacheHulls',{[]}, 'hLabel',{hTimeLabel}), 'Toolbar','figure');
    set(hPreviewFig, 'WindowScrollWheelFcn',@windowScrollWheel, 'KeyPressFcn',@windowKeyPress, 'CloseRequestFcn','');
    
    hSegPropDlg = initSegPropDialog(hPreviewFig);
    drawPreviewImage(hPreviewFig);
    
    uiwait(hSegPropDlg);
end

function windowKeyPress(src, event)
    previewInfo = get(src, 'UserData');
    
    if ( strcmpi(event.Key, 'uparrow') )
        previewInfo.time = incrementFrame(previewInfo.time, -1);
    elseif ( strcmpi(event.Key, 'leftarrow') )
        previewInfo.time = incrementFrame(previewInfo.time, -1);
    elseif ( strcmpi(event.Key, 'downarrow') )
        previewInfo.time = incrementFrame(previewInfo.time, +1);
    elseif ( strcmpi(event.Key, 'rightarrow') )
        previewInfo.time = incrementFrame(previewInfo.time, +1);
    elseif ( strcmpi(event.Key, 'F12') )
        previewInfo.showInterior = ~previewInfo.showInterior;
    elseif ( strcmpi(event.Key,'t') && any(strcmpi('control',event.Modifier)) )
        chkTime = inputdlg('Enter frame number:','Go to Time',1,{num2str(previewInfo.time)});
        if (isempty(chkTime))
            return;
        end
        
        newTime = str2double(chkTime{1});
        if ( isnan(newTime) )
            return;
        end
        
        newTime = setTime(newTime);
        previewInfo.time = newTime;
    end
    
    set(src, 'UserData',previewInfo);
    
    drawPreviewImage(src);
end

function windowScrollWheel(src, event)
    previewInfo = get(src, 'UserData');
    time = incrementFrame(previewInfo.time, event.VerticalScrollCount);
    
    previewInfo.time = time;
    set(src, 'UserData',previewInfo);
    
    drawPreviewImage(src);
end

function time = setTime(time)
    if ( time < 1 )
        time = 1;
    end
    
    if ( time > Metadata.GetNumberOfFrames() )
        time = Metadata.GetNumberOfFrames();
    end
end

function newTime = incrementFrame(time, delta)
    newTime = time + delta;
    
    if ( newTime < 1 )
        newTime = 1;
    end
    
    if ( newTime > Metadata.GetNumberOfFrames() )
        newTime = newTime - Metadata.GetNumberOfFrames();
    end
end

function drawPreviewImage(hFig)
    hAx = get(hFig, 'CurrentAxes');
    frameInfo = get(hFig, 'UserData');
    
    set(frameInfo.hLabel, 'String',['Time: ' num2str(frameInfo.time)]);
    
    imSet = Helper.LoadIntensityImageSet(frameInfo.time);
    im = imSet{frameInfo.chan};
    
    if ( isempty(im) )
        im = 0.5*ones(Metadata.GetDimensions());
    end
    
    imMax = max(im(:));
    im = mat2gray(im,[0 imMax]);
    
    imDims = Metadata.GetDimensions();
    
    xl=xlim(hAx);
    yl=ylim(hAx);
    if ( all(xl == [0 1]) )
        xl = [1 imDims(1)];
        yl = [1 imDims(2)];
    end

    hold(hAx, 'off');
    imagesc(im, 'Parent',hAx, [0 1]);
    colormap(hAx, gray(256));
    
    zoom(hAx, 'reset');
    
    xlim(hAx, xl);
    ylim(hAx, yl);
    
    axis(hAx,'off');
    
    hold(hAx, 'all');
    
    if ( ~isempty(frameInfo.cacheHulls) && (frameInfo.cacheHulls(1).time == frameInfo.time) )
        drawSegHulls(hFig, frameInfo.cacheHulls, frameInfo.showInterior);
    end
    
    drawnow();
end

function drawSegHulls(hFig,segHulls, bShowInterior)
    hAx = get(hFig, 'CurrentAxes');
    hold(hAx, 'on');
    
    cmap = hsv(31);
    if ( bShowInterior )
        for i=1:length(segHulls)
            colorIdx = mod(i-1,31)+1;
            
            rcCoords = Helper.IndexToCoord(Metadata.GetDimensions(), segHulls(i).indexPixels);
            plot(hAx, rcCoords(:,2),rcCoords(:,1), '.', 'Color',cmap(colorIdx,:));
        end
    end
    
    for i=1:length(segHulls)
        plot(hAx, segHulls(i).points(:,1),segHulls(i).points(:,2), '-r');
    end
    hold(hAx, 'off');
end

function dialogInfo = setNewSegParams(dialogInfo)
    selectSeg = dialogInfo.selectSeg;
    chkSegInfo = dialogInfo.segInfo(selectSeg);
    
    for i=1:length(chkSegInfo.params)
        paramValStr = get(dialogInfo.hParams(i), 'String');
        
        chkType = chkSegInfo.params(i).value;
        if ( isa(chkType, 'char') )
            chkSegInfo.params(i).value = paramValStr;
        elseif ( isa(chkType, 'double') )
            chkSegInfo.params(i).value = str2double(paramValStr);
        else
            error('Unexpected parameter type');
        end
    end
    
    dialogInfo.segInfo(selectSeg) = chkSegInfo;
end

function [segFunc,segArgs] = getSegInfo(dialogInfo)
    selectSeg = dialogInfo.selectSeg;
    chkSegInfo = dialogInfo.segInfo(selectSeg);
    
    segFunc = chkSegInfo.func;
    segArgs = arrayfun(@(x)(x.value), chkSegInfo.params, 'UniformOutput',0);
end

function previewSeg(src,event)
    hPreviewSeg = src;
    hSegPropDlg = get(hPreviewSeg,'Parent');
    
    dialogInfo = get(hSegPropDlg, 'UserData');
    dialogInfo = setNewSegParams(dialogInfo);
    set(hSegPropDlg, 'UserData',dialogInfo);
    
    hPreviewFig = dialogInfo.hPreviewFig;
    frameInfo = get(hPreviewFig, 'UserData');
    
    set(hPreviewFig, 'Pointer','watch');
    set(hSegPropDlg, 'Pointer','watch');
    drawnow();
    
    imSet = Helper.LoadIntensityImageSet(frameInfo.time);
    im = imSet{frameInfo.chan};
    
    if ( ~isempty(im) )
        [segFunc, segArgs] = getSegInfo(dialogInfo);
        
        segHulls = segFunc(imSet, frameInfo.chan, frameInfo.time, segArgs{:});
    end
    
    validHulls = [];
    for i=1:length(segHulls)
        validHulls = [validHulls Hulls.CreateHull(Metadata.GetDimensions(), segHulls(i).indexPixels, frameInfo.time, false, segHulls(i).tag)];
    end
    
    frameInfo.cacheHulls = validHulls;
    
    set(hPreviewFig, 'Pointer','arrow');
    set(hSegPropDlg, 'Pointer','arrow');
    
    bShowInterior = frameInfo.showInterior;
    
    set(hPreviewFig, 'UserData',frameInfo);
    
    drawPreviewImage(hPreviewFig);
end

function runSeg(src,event)
    hRunSeg = src;
    hSegPropDlg = get(hRunSeg,'Parent');
    
    dialogInfo = get(hSegPropDlg, 'UserData');
    dialogInfo = setNewSegParams(dialogInfo);
    set(hSegPropDlg, 'UserData',dialogInfo);
    
    selectSeg = dialogInfo.selectSeg;
    
    SupportedTypes = Load.GetSupportedCellTypes();
    cellType = SupportedTypes(selectSeg).name;
    Load.AddConstant('cellType',cellType,1);
    Load.AddConstant('primaryChannel', dialogInfo.selectChan,1);
    
    Load.AddConstant('segInfo', dialogInfo.segInfo(selectSeg),1);
    
    closeFigures(hSegPropDlg,[]);
end

function defaultParams(src,event)
    hResetDefault = src;
    hSegPropDlg = get(hResetDefault,'Parent');
    
    dialogInfo = get(hSegPropDlg, 'UserData');
    selectSeg = dialogInfo.selectSeg;
    
    SupportedTypes = Load.GetSupportedCellTypes();
    defaultSegInfo = SupportedTypes(selectSeg).segRoutine;
    
    dialogInfo.segInfo(selectSeg) = defaultSegInfo;
    set(hSegPropDlg, 'UserData',dialogInfo);
    
    setParamValues(hSegPropDlg, selectSeg);
end

function closeFigures(src,event)
    hSegPropDlg = src;
    dialogInfo = get(hSegPropDlg, 'UserData');
    
    hPreviewFig = dialogInfo.hPreviewFig;
    delete(hPreviewFig);
    delete(hSegPropDlg);
end

function hSegPropDlg = initSegPropDialog(hFig)
    hSegPropDlg = dialog('Name','Select Segmentation Properties', 'Visible','on', 'WindowStyle','normal', 'CloseRequestFcn',@closeFigures);
%     WinOnTop(hSegPropDlg,true);
    
    SupportedTypes = Load.GetSupportedCellTypes();
    
    typeNames = {SupportedTypes.name};
    chanStr = arrayfun(@(x)(num2str(x)), 1:Metadata.GetNumberOfChannels(), 'UniformOutput',0);
    
    hCellBox = uicontrol(hSegPropDlg, 'Style','popupmenu', 'String',typeNames, 'Callback',@selectedCellType, 'Position',[20 20 100 20]);
    hChanBox = uicontrol(hSegPropDlg, 'Style','popupmenu', 'String',chanStr, 'Callback',@selectedChannel, 'Position',[20 20 100 20]);
    hPreviewSeg = uicontrol(hSegPropDlg, 'Style','pushbutton', 'String','Preview Segmentation', 'Callback',@previewSeg, 'Position',[20 20 100 20]);
    hRunSeg = uicontrol(hSegPropDlg, 'Style','pushbutton', 'String','Run Full Segmentation', 'Callback',@runSeg, 'Position',[20 20 100 20]);
    hCancel = uicontrol(hSegPropDlg, 'Style','pushbutton', 'String','Default Parameters', 'Callback',@defaultParams, 'Position',[20 20 100 20]);
    
    segInfo = [SupportedTypes.segRoutine];
    dialogInfo = struct('hPreviewFig',{hFig}, 'hKeep',{[hCellBox hChanBox hPreviewSeg hRunSeg hCancel]}, 'hParams',{[]}, 'selectSeg',{1}, 'segInfo',{segInfo});
    set(hSegPropDlg, 'UserData',dialogInfo);
    
    selectedCellType(hCellBox, [])
    selectedChannel(hChanBox,[]);
end

function selectedChannel(src,event)
    hChanBox = src;
    hSegPropDlg = get(hChanBox,'Parent');
    
    selectedIdx = get(hChanBox, 'Value');
    chanStr = get(hChanBox,'String');
    selectedChan = str2double(chanStr{selectedIdx});
    
    dialogInfo = get(hSegPropDlg, 'UserData');
    dialogInfo.selectChan = selectedChan;
    set(hSegPropDlg, 'UserData',dialogInfo);
    
    hPreviewFig = dialogInfo.hPreviewFig;
    
    previewInfo = get(hPreviewFig, 'UserData');
    previewInfo.chan = selectedChan;
    set(hPreviewFig, 'UserData',previewInfo);
    
    drawPreviewImage(hPreviewFig);
end

function selectedCellType(src,event)
    hCellBox = src;
    hSegPropDlg = get(hCellBox,'Parent');
    
    selectedIdx = get(hCellBox, 'Value');
    createParamControls(hSegPropDlg, selectedIdx);
    setParamValues(hSegPropDlg, selectedIdx);
    
    dialogInfo = get(hSegPropDlg, 'UserData');
    dialogInfo.selectSeg = selectedIdx;
    set(hSegPropDlg, 'UserData',dialogInfo);
    
    %Clear cached hull data on algorithm selection change.
    hPreviewFig = dialogInfo.hPreviewFig;
    frameInfo = get(hPreviewFig, 'UserData');
    frameInfo.cacheHulls = [];
    set(hPreviewFig, 'UserData',frameInfo);
    
    drawPreviewImage(hPreviewFig);
end

function setParamValues(hDlg, selectIdx)
    dialogInfo = get(hDlg, 'UserData');
    hParams = dialogInfo.hParams;
    
    segInfo = dialogInfo.segInfo(selectIdx);
    for i=1:length(hParams);
        paramValue = segInfo.params(i).value;
        set(hParams(i), 'String', num2str(paramValue));
    end
end

function createParamControls(hDlg, selectIdx)
    labelWidth = 70;
    labelHeight = 16;
    labelPad = 1;
    
    controlHeight = 22;
    controlWidth = 100;
    
    buttonWidth = 130;
    
    controlPad = 5;
    controlLeft = 2*controlPad;
    
    dialogInfo = get(hDlg, 'UserData');
    
    hDlgChildren = get(hDlg, 'Children');
    bRmChildren = ~ismember(hDlgChildren, dialogInfo.hKeep);
    
    hChildren = hDlgChildren(bRmChildren);
    for i=1:length(hChildren)
        delete(hChildren(i));
    end
    
    numParams = length(dialogInfo.segInfo(selectIdx).params);
    segFunc = dialogInfo.segInfo(selectIdx).func;
    
    %% Load function help information
    funcName = char(segFunc);
    helpStruct = Dev.FrameSegHelp(funcName);
    
    numControls = max(3, numParams + 2);
    dialogWidth = 2*controlPad + labelWidth + controlPad + controlWidth + 2*controlPad + buttonWidth + 2*controlPad;
    dialogHeight = controlPad + controlHeight*numControls + 2*controlPad*(numControls-1) + controlPad;
    
    dialogPos = get(hDlg, 'Position');
    set(hDlg, 'Position',[dialogPos(1:2) dialogWidth dialogHeight]);
    
    hCellBox = dialogInfo.hKeep(1);
    hChanBox = dialogInfo.hKeep(2);
    
    curControlPos = [controlLeft, dialogHeight-controlPad];
    curControlPos = layoutLabelControls(hCellBox, curControlPos, 'Cell Type: ', sprintf(helpStruct.summary));
    curControlPos = layoutLabelControls(hChanBox, curControlPos, 'Channel: ', '');
    
    %% Try to find parameter help in function documentation to put in label/textbox tooltips
    hParams = zeros(1,numParams);
    for i=1:numParams
        paramName = dialogInfo.segInfo(selectIdx).params(i).name;
        
        hParams(i) = uicontrol(hDlg, 'Style','edit');
        curControlPos = layoutLabelControls(hParams(i), curControlPos, [paramName ': '], sprintf(helpStruct.paramHelp{i}));
    end
    
    hButtons = dialogInfo.hKeep(3:end);
    curControlPos = [controlLeft + labelWidth + controlPad + controlWidth + 2*controlPad, dialogHeight-controlPad];
    for i=1:length(hButtons);
        curControlPos = layoutButtonControls(hButtons(i), curControlPos);
    end
    
    dialogInfo.hParams = hParams;
    set(hDlg, 'UserData',dialogInfo);
    
    function newPos = layoutLabelControls(hCtrl, startPos, labelStr, tooltip)
        newPos = startPos - [0, controlHeight];
        
        hLabel = uicontrol(hDlg, 'Style','text', 'HorizontalAlignment','right', 'String',labelStr, 'Position',[newPos(1), newPos(2)+labelPad, labelWidth, labelHeight]);
        set(hCtrl, 'Position',[newPos(1) + labelWidth + controlPad, newPos(2), controlWidth, controlHeight]);
        
        set(hCtrl, 'ToolTipString',tooltip);
        set(hLabel, 'ToolTipString',tooltip);
        
        newPos = newPos - [0, 2*controlPad];
    end

    function newPos = layoutButtonControls(hCtrl, startPos)
        newPos = startPos - [0, controlHeight];
        set(hCtrl, 'Position',[newPos(1) + controlPad, newPos(2), buttonWidth, controlHeight]);
        
        newPos = newPos - [0, 2*controlPad];
    end
end
