function UpdateMitosisTrackingIndicators()
    global Figures CellTracks MitosisEditStruct
    
    if ( isempty(MitosisEditStruct) )
        return;
    end
    
    MitosisEditStruct.selectedTrackID = [];
    if ( isempty(MitosisEditStruct.editingHullID) )
        clearIndicators();
        return;
    end
    
    if ( isempty(MitosisEditStruct.selectCosts) )
        clearIndicators();
        return;
    end
    
    if ( isempty(Figures.tree.trackMap) )
        clearIndicators();
        return;
    end
    
    chkTracks = validCurrentTreeTracks();
    chkCosts = values(MitosisEditStruct.selectCosts,num2cell(chkTracks));
    [minCost minIdx] = min(abs([chkCosts{:}]));
    
    selectedTrackID = chkTracks(minIdx);
    MitosisEditStruct.selectedTrackID = selectedTrackID;
    
    xVal = Figures.tree.trackMap(selectedTrackID).xCenter;
    yStart = CellTracks(selectedTrackID).startTime;
    if ( MitosisEditStruct.selectCosts(selectedTrackID) < 0 )
        yStart = CellTracks(selectedTrackID).endTime;
    end
    yEnd = Figures.time;
    
    drawString = num2str(selectedTrackID);
    [fontSize circleSize] = UI.GetFontShapeSizes(length(drawString));
    
    trackColor = CellTracks(selectedTrackID).color.background;
    textColor = CellTracks(selectedTrackID).color.text;
    
    markerScale = 1.2;
    
    curAx = get(Figures.tree.handle, 'CurrentAxes');
    if ( Helper.ValidUIHandle(Figures.tree.trackingLine) )
        set(Figures.tree.trackingLine, 'XData',[xVal xVal], 'YData',[yStart yEnd]);
        set(Figures.tree.trackingBacks, 'XData',xVal, 'YData',yEnd, 'MarkerFaceColor',trackColor, 'MarkerSize',markerScale*circleSize);
        set(Figures.tree.trackingLabel, 'Position',[xVal yEnd], 'String',drawString, 'Color',textColor, 'FontWeight','bold', 'FontSize',fontSize);
    else
        hold(curAx,'on');
        
        hLine = plot(curAx, [xVal xVal], [yStart yEnd], '-r', 'LineWidth',1.5);
        hMarker = plot(curAx, xVal,yEnd, 'o', 'MarkerEdgeColor','r', 'MarkerFaceColor',trackColor, 'MarkerSize',markerScale*circleSize);
        hLabel = text(xVal,yEnd, drawString, 'Parent',curAx, 'Color',textColor, 'FontWeight','bold', 'FontSize',fontSize, 'HorizontalAlignment','center');
        
        Figures.tree.trackingLine = hLine;
        Figures.tree.trackingBacks = hMarker;
        Figures.tree.trackingLabel = hLabel;
    end
    
%     % Debugging path code:
%     if ( isfield(Figures.tree,'debugLineList') )
%         bValidHandles = Helper.ValidUIHandle(Figures.tree.debugLineList);
%         validHandles = Figures.tree.debugLineList(bValidHandles);
%         for i=1:length(validHandles)
%             delete(validHandles(i));
%         end
%         Figures.tree.debugLineList = [];
%     end
%     
%     Figures.tree.debugLineList = text(xVal,yEnd-10, num2str(minCost));
%     
%     hold(curAx,'on');
%     curTrackID = selectedTrackID;
%     while ( curTrackID > 0 )
%         predID = MitosisEditStruct.selectPath(curTrackID);
%         edgeDir = sign(MitosisEditStruct.selectCosts(curTrackID));
%         
%         xVal = Figures.tree.trackMap(curTrackID).xCenter;
%         yStart = CellTracks(curTrackID).startTime;
%         yEnd = CellTracks(curTrackID).endTime+1;
%         if ( edgeDir < 0 )
%             yStart = CellTracks(curTrackID).endTime+1;
%             yEnd = CellTracks(curTrackID).startTime;
%         end
%         
%         hvLine = [];
%         hhLine = [];
%         if ( curTrackID ~= selectedTrackID )
%             hvLine = plot(curAx, [xVal xVal], [yStart yEnd], '-r', 'LineWidth',1.5);
%         end
%         if ( predID > 0 )
%             xNext = Figures.tree.trackMap(predID).xCenter;
%             hhLine = plot(curAx, [xVal xNext], [yStart yStart], '-r', 'LineWidth',1.5);
%         end
%         
%         Figures.tree.debugLineList = [Figures.tree.debugLineList hvLine hhLine];
%         curTrackID = predID;
%     end
end

function clearIndicators()
    global Figures
    
    if ( Helper.ValidUIHandle(Figures.tree.trackingLine) )
        delete(Figures.tree.trackingLine);
        delete(Figures.tree.trackingBacks);
        delete(Figures.tree.trackingLabel);
    end
    
%     %Debugging
%     if ( isfield(Figures.tree,'debugLineList') )
%         bValidHandles = Helper.ValidUIHandle(Figures.tree.debugLineList);
%         validHandles = Figures.tree.debugLineList(bValidHandles);
%         for i=1:length(validHandles)
%             delete(validHandles(i));
%         end
%         Figures.tree.debugLineList = [];
%     end
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
