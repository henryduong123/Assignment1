function hSegPropDlg = SegPropDialog(hFig)
    if ( ~exist('hFig','var') )
        hFig = [];
    end
    
    hSegPropDlg = dialog('Name','Select Segmentation Properties', 'Visible','on', 'WindowStyle','normal', 'CloseRequestFcn',@closeFigures);
    
    SupportedTypes = Load.GetSupportedCellTypes();
    
    typeNames = {SupportedTypes.name};
    
    % Handle the case that we don't know number of channels
    if ( Metadata.GetNumberOfChannels() < 1 )
        chanStr = {'1'};
    else
        chanStr = arrayfun(@(x)(num2str(x)), 1:Metadata.GetNumberOfChannels(), 'UniformOutput',0);
    end
    
    enableSegPreview = 'off';
    if ( ishandle(hFig) )
       enableSegPreview = 'on';
    end
    
    
    hCellBox = uicontrol(hSegPropDlg, 'Style','popupmenu', 'String',typeNames, 'Callback',@selectedCellType, 'Position',[20 20 100 20]);
    
    % Handle the case that we don't know number of channels, use editbox
    if ( Metadata.GetNumberOfChannels() < 1 )
        hChanBox = uicontrol(hSegPropDlg, 'Style','edit', 'String',chanStr, 'Callback',@selectedChannel, 'Position',[20 20 100 20]);
    else
        hChanBox = uicontrol(hSegPropDlg, 'Style','popupmenu', 'String',chanStr, 'Callback',@selectedChannel, 'Position',[20 20 100 20]);
    end
    
    hPreviewSeg = uicontrol(hSegPropDlg, 'Style','pushbutton', 'String','Preview Segmentation', 'Callback',@previewSeg, 'Position',[20 20 100 20], 'Enable',enableSegPreview);
    hRunSeg = uicontrol(hSegPropDlg, 'Style','pushbutton', 'String','Run Full Segmentation', 'Callback',@runSeg, 'Position',[20 20 100 20]);
    hCancel = uicontrol(hSegPropDlg, 'Style','pushbutton', 'String','Default Parameters', 'Callback',@defaultParams, 'Position',[20 20 100 20]);
    
    segInfo = [SupportedTypes.segRoutine];
    dialogInfo = struct('hPreviewFig',{hFig}, 'hKeep',{[hCellBox hChanBox hPreviewSeg hRunSeg hCancel]}, 'hParams',{[]}, 'selectSeg',{1}, 'segInfo',{segInfo});
    set(hSegPropDlg, 'UserData',dialogInfo);
    
    selectedCellType(hCellBox, [])
    selectedChannel(hChanBox,[]);
end

%% Update preview window when new primary channel selected for viewing
function selectedChannel(src,event)
    hChanBox = src;
    hSegPropDlg = get(hChanBox,'Parent');
    
    selectedIdx = get(hChanBox, 'Value');
    chanStr = get(hChanBox,'String');
    
    
    if ( selectedIdx < 1 )
        selectedChan = str2double(chanStr);
    else
        selectedChan = str2double(chanStr{selectedIdx});
    end
    
    dialogInfo = get(hSegPropDlg, 'UserData');
    dialogInfo.selectChan = selectedChan;
    set(hSegPropDlg, 'UserData',dialogInfo);
    
    hPreviewFig = dialogInfo.hPreviewFig;
    if ( isempty(hPreviewFig) )
        return;
    end
    
    previewInfo = get(hPreviewFig, 'UserData');
    previewInfo.chan = selectedChan;
    set(hPreviewFig, 'UserData',previewInfo);
    
    forceRefreshPreview(hPreviewFig);
end


%% Update parameters based on new cell type selection
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
    if ( isempty(hPreviewFig) )
        return;
    end
    
    frameInfo = get(hPreviewFig, 'UserData');
    frameInfo.cacheHulls = [];
    set(hPreviewFig, 'UserData',frameInfo);
    
    forceRefreshPreview(hPreviewFig);
end

%% Set new segmentation parameters
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

%% Finalize parameter selection and close dialog boxes
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

%% Preview single frame segmentation
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
        validHulls = [validHulls Hulls.CreateHull(Metadata.GetDimensions('rc'), segHulls(i).indexPixels, frameInfo.time, false, segHulls(i).tag)];
    end
    
    frameInfo.cacheHulls = validHulls;
    
    set(hPreviewFig, 'Pointer','arrow');
    set(hSegPropDlg, 'Pointer','arrow');
    
    set(hPreviewFig, 'UserData',frameInfo);
    
    forceRefreshPreview(hPreviewFig);
end

%% Hack to force redraw of preview figure
function forceRefreshPreview(hFig)
    scrollFunc = get(hFig, 'WindowScrollWheelFcn');
    scrollFunc(hFig,struct('VerticalScrollCount',{0}));
end

%% Reset current cell parameters to defaults
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

%% Set up parameter value display
function setParamValues(hDlg, selectIdx)
    dialogInfo = get(hDlg, 'UserData');
    hParams = dialogInfo.hParams;
    
    segInfo = dialogInfo.segInfo(selectIdx);
    for i=1:length(hParams);
        paramValue = segInfo.params(i).value;
        set(hParams(i), 'String', num2str(paramValue));
    end
end


%% Close this figure and possibly associated preview windows.
function closeFigures(src,event)
    hSegPropDlg = src;
    dialogInfo = get(hSegPropDlg, 'UserData');
    
    hPreviewFig = dialogInfo.hPreviewFig;
    if ( ~isempty(hPreviewFig) )
        delete(hPreviewFig);
    end
    
    delete(hSegPropDlg);
end

%%
function [segFunc,segArgs] = getSegInfo(dialogInfo)
    selectSeg = dialogInfo.selectSeg;
    chkSegInfo = dialogInfo.segInfo(selectSeg);
    
    segFunc = chkSegInfo.func;
    segArgs = arrayfun(@(x)(x.value), chkSegInfo.params, 'UniformOutput',0);
end


%% Create all controls associated with cell type parameters
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


