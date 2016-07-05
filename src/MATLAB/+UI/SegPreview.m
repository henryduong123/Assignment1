% Creates a temporary image and segmentation visualization window and
% parameters dialog box for previewing segmentation before running.

function SegPreview()
	hPreviewFig = figure();
    
    hAx = axes('Parent',hPreviewFig, 'Position',[0.01 0.01 0.98 0.98], 'XTick',[],'YTick',[]);
    hTimeLabel = uicontrol(hPreviewFig,'Style','text', 'Position',[1 0 60 20],'String', ['Time: ' num2str(1)]);
    set(hPreviewFig, 'CurrentAxes',hAx, 'NumberTitle','off', 'Name',[Metadata.GetDatasetName() ' Preview']);
    
    set(hPreviewFig, 'UserData',struct('time',{1}, 'chan',{1}, 'showInterior',{false}, 'cacheHulls',{[]}, 'hLabel',{hTimeLabel}), 'Toolbar','figure');
    set(hPreviewFig, 'WindowScrollWheelFcn',@windowScrollWheel, 'KeyPressFcn',@windowKeyPress, 'CloseRequestFcn','');
    
    hSegPropDlg = UI.SegPropDialog(hPreviewFig);
    drawPreviewImage(hPreviewFig);
    
    uiwait(hSegPropDlg);
end


%% Load and render a preview image with current hull overlays
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

%% Render hull overlays on image
function drawSegHulls(hFig,segHulls, bShowInterior)
    hAx = get(hFig, 'CurrentAxes');
    hold(hAx, 'on');
    
    cmap = hsv(31);
    if ( bShowInterior )
        for i=1:length(segHulls)
            colorIdx = mod(i-1,31)+1;
            
            rcCoords = Utils.IndToCoord(Metadata.GetDimensions('rc'), segHulls(i).indexPixels);
            plot(hAx, rcCoords(:,2),rcCoords(:,1), '.', 'Color',cmap(colorIdx,:));
        end
    end
    
    for i=1:length(segHulls)
        plot(hAx, segHulls(i).points(:,1),segHulls(i).points(:,2), '-r');
    end
    hold(hAx, 'off');
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
