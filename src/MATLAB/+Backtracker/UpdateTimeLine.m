function UpdateTimeLine()
    global Figures

    curAx = get(Figures.tree.handle, 'CurrentAxes');
    xlims = xlim(curAx);
    
    if( Helper.ValidUIHandle(Figures.tree.timeIndicatorLine) )
        set(Figures.tree.timeIndicatorLine,...
            'YData',        [Figures.time Figures.time],...
            'XData',        xlims);
    else
        Figures.tree.timeIndicatorLine = line(...
            xlims,...
            [Figures.time Figures.time],...
            'color',        'red',...
            'linewidth',    1,...
            'EraseMode',    'xor',...
            'Tag',          'timeIndicatorLine',...
            'Parent',       curAx);
    end
    
%     uistack(Figures.tree.timeIndicatorLine, 'bottom');
    
    updateTrackingIndicators();
end

function updateTrackingIndicators()
    global Figures CellTracks SelectStruct
    
    SelectStruct.selectedTrackID = [];
    if ( isempty(SelectStruct.editingHullID) )
        clearIndicators();
        return;
    end
    
    if ( isempty(SelectStruct.selectCosts) )
        clearIndicators();
        return;
    end
    
    if ( isempty(Figures.tree.trackMap) )
        clearIndicators();
        return;
    end
    
    chkTracks = validCurrentTreeTracks();
    chkCosts = values(SelectStruct.selectCosts,num2cell(chkTracks));
    [minCost minIdx] = min(abs([chkCosts{:}]));
    
    selectedTrackID = chkTracks(minIdx);
    SelectStruct.selectedTrackID = selectedTrackID;
    
    selectedTrackID = Backtracker.GetSelectedTrackID();
    
    xVal = Figures.tree.trackMap(selectedTrackID).xCenter;
    yStart = CellTracks(selectedTrackID).startTime;
    if ( SelectStruct.selectCosts(selectedTrackID) < 0 )
        yStart = CellTracks(selectedTrackID).endTime;
    end
    yEnd = Figures.time;
    
    drawString = num2str(selectedTrackID);
    [fontSize circleSize] = UI.GetFontShapeSizes(length(drawString));
    
    trackColor = CellTracks(selectedTrackID).color.background;
    textColor = CellTracks(selectedTrackID).color.text;
    
    curAx = get(Figures.tree.handle, 'CurrentAxes');
    if ( Helper.ValidUIHandle(Figures.tree.trackingLine) )
        set(Figures.tree.trackingLine, 'XData',[xVal xVal], 'YData',[yStart yEnd]);
        set(Figures.tree.trackingBacks, 'XData',xVal, 'YData',yEnd, 'MarkerFaceColor',trackColor, 'MarkerSize',circleSize);
        set(Figures.tree.trackingLabel, 'Position',[xVal yEnd], 'String',drawString, 'Color',textColor, 'FontSize',fontSize);
    else
        hold(curAx,'on');
        
        hLine = plot(curAx, [xVal xVal], [yStart yEnd], '-r', 'LineWidth',1.5);
        hMarker = plot(curAx, xVal,yEnd, 'o', 'MarkerEdgeColor','r', 'MarkerFaceColor',trackColor, 'MarkerSize',circleSize);
        hLabel = text(xVal,yEnd, drawString, 'Parent',curAx, 'Color',textColor, 'FontSize',fontSize, 'HorizontalAlignment','center');
        
        Figures.tree.trackingLine = hLine;
        Figures.tree.trackingBacks = hMarker;
        Figures.tree.trackingLabel = hLabel;
    end
    
    % Debugging path code:
    if ( isfield(Figures.tree,'debugLineList') )
        bValidHandles = Helper.ValidUIHandle(Figures.tree.debugLineList);
        validHandles = Figures.tree.debugLineList(bValidHandles);
        for i=1:length(validHandles)
            delete(validHandles(i));
        end
        Figures.tree.debugLineList = [];
    end
    
    Figures.tree.debugLineList = text(xVal,yEnd-10, num2str(minCost));
    
    hold(curAx,'on');
    curTrackID = selectedTrackID;
    while ( curTrackID > 0 )
        predID = SelectStruct.selectPath(curTrackID);
        edgeDir = sign(SelectStruct.selectCosts(curTrackID));
        
        xVal = Figures.tree.trackMap(curTrackID).xCenter;
        yStart = CellTracks(curTrackID).startTime;
        yEnd = CellTracks(curTrackID).endTime+1;
        if ( edgeDir < 0 )
            yStart = CellTracks(curTrackID).endTime+1;
            yEnd = CellTracks(curTrackID).startTime;
        end
        
        hvLine = [];
        hhLine = [];
        if ( curTrackID ~= selectedTrackID )
            hvLine = plot(curAx, [xVal xVal], [yStart yEnd], '-r', 'LineWidth',1.5);
        end
        if ( predID > 0 )
            xNext = Figures.tree.trackMap(predID).xCenter;
            hhLine = plot(curAx, [xVal xNext], [yStart yStart], '-r', 'LineWidth',1.5);
        end
        
        Figures.tree.debugLineList = [Figures.tree.debugLineList hvLine hhLine];
        curTrackID = predID;
    end
end

function clearIndicators()
    global Figures
    
    if ( Helper.ValidUIHandle(Figures.tree.trackingLine) )
        delete(Figures.tree.trackingLine);
        delete(Figures.tree.trackingBacks);
        delete(Figures.tree.trackingLabel);
    end
    
    %Debugging
    if ( isfield(Figures.tree,'debugLineList') )
        bValidHandles = Helper.ValidUIHandle(Figures.tree.debugLineList);
        validHandles = Figures.tree.debugLineList(bValidHandles);
        for i=1:length(validHandles)
            delete(validHandles(i));
        end
        Figures.tree.debugLineList = [];
    end
end

function chkTracks = validCurrentTreeTracks()
    global Figures CellFamilies CellTracks
    
    familyID = Figures.tree.familyID;
    time = Figures.time;
    
    trackList = CellFamilies(familyID).tracks;
    rootTrackID = CellFamilies(familyID).rootTrackID;
    
    bLeaves = arrayfun(@(x)(isempty(x.childrenTracks)), CellTracks(trackList));
    bStartBefore = ([CellTracks(trackList).startTime] <= time);
    bEndAfter = ([CellTracks(trackList).endTime] >= time);
    
    bChkTracks = (bStartBefore & (bLeaves | bEndAfter));
    chkTracks = trackList(bChkTracks);
    
    if ( isempty(chkTracks) )
        chkTracks = rootTrackID;
    end
end
