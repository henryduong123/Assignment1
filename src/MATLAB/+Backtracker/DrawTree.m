function DrawTree(familyID)
    global CONSTANTS bDirty Figures CellFamilies CellTracks CellHulls HashedCells
%     persistent trackHandleMap drawnFamilyID
    
    bForceUpdate = false;
    if ( ~exist('familyID','var') )
        bForceUpdate = true;
        familyID = Figures.tree.familyID;
    end
    
    endTime = length(HashedCells);
    
    curAx = get(Figures.tree.handle, 'CurrentAxes');
    if ( isempty(curAx) )
        curAx = axes('Parent', Figures.tree.handle);

        set(curAx,...
            'YDir',     'reverse',...
            'YLim',     [-25 endTime],...
            'Position', [.06 .06 .90 .90],...
            'XColor',   'w',...
            'XTick',    [],...
            'Box',      'off',...
            'DrawMode', 'fast');
    end
    
    if ( bDirty )
        set(Figures.tree.handle, 'Name',[CONSTANTS.datasetName ' Trees *']);
    else
        set(Figures.tree.handle, 'Name',[CONSTANTS.datasetName ' Trees']);
    end
    
    if ( isempty(familyID) )
        return;
    end
    
    if ( ~isempty(Figures.tree.familyID) )
        if ( ~bForceUpdate && (Figures.tree.familyID == familyID) )
            return;
        end
    end
    
    Figures.tree.familyID = familyID;
    rootTrackID = CellFamilies(familyID).rootTrackID;
    
    trackHeights = Backtracker.ComputeTrackHeights(rootTrackID);
    trackMap = containers.Map('KeyType', 'uint32', 'ValueType', 'any');
    [sortedTracks bFamHasPheno] = simpleTraverseTree(rootTrackID, 0, trackMap, trackHeights);
    
    Figures.tree.trackMap = trackMap;
    
    xBox = trackMap(rootTrackID).xBox + [-0.5 0.5];
    
    hold(curAx,'on');
    cla(curAx);
    set(curAx, 'YDir','reverse','XLim',xBox, 'YLim',[-25 endTime]);
    
    for i=1:length(sortedTracks)
        childrenTracks = CellTracks(sortedTracks(i)).childrenTracks;
        if ( ~isempty(childrenTracks) )
            xChildren = [trackMap(childrenTracks(1)).xCenter trackMap(childrenTracks(2)).xCenter];
            drawHorizontalEdge(curAx, xChildren, CellTracks(sortedTracks(i)).endTime+1);
        end
    end
    
    for i=1:length(sortedTracks)
        drawTrackEdge(curAx, sortedTracks(i), trackMap);
    end
    
    for i=1:length(sortedTracks)
        drawTrackLabel(curAx, sortedTracks(i), trackMap);
    end
end

%% Drawing functions

function drawHorizontalEdge(hAx, xVals, yVal)
    plot(hAx, xVals, [yVal yVal], '-k');
end

function drawTrackEdge(hAx, trackID, trackMap)
    global CellTracks
    
    xVal = trackMap(trackID).xCenter;
    yStart = CellTracks(trackID).startTime;
    yEnd = CellTracks(trackID).endTime + 1;
    
    phenotype = Tracks.GetTrackPhenotype(trackID);
    if ( phenotype ~= 1 )
        hLines = plot(hAx, [xVal xVal], [yStart yEnd], '-k');
    else
        yPhenos = Tracks.GetTrackPhenoypeTimes(trackID);
        
        hLines(1) = plot(hAx, [xVal xVal], [yStart yPhenos(end)], '-k');
        hLines(2) = plot(hAx, [xVal xVal], [yPhenos(end) yEnd], '--k');
    end
    
    for i=1:length(hLines)
        set(hLines(i),'ButtonDownFcn', @(src,evt)(trackButtonDown(trackID)));
    end
end

function drawTrackLabel(hAx, trackID, trackMap)
    global CellTracks
    
    xVal = trackMap(trackID).xCenter;
    yVal = trackMap(trackID).yBox(1);
    
    drawString = num2str(trackID);
    [fontSize circleSize] = UI.GetFontShapeSizes(length(drawString));
    
    trackColor = CellTracks(trackID).color.background;
    textColor = CellTracks(trackID).color.text;
    
    % Plot Label
    hMarker = plot(hAx, xVal,yVal, 'o', 'MarkerEdgeColor',trackColor, 'MarkerFaceColor',trackColor, 'MarkerSize',circleSize);
    hLabel = text(xVal,yVal, drawString, 'Parent',hAx, 'Color',textColor, 'FontSize',fontSize, 'HorizontalAlignment','center');
    
    hCommon = [hMarker hLabel];
    for i=1:length(hCommon)
        set(hCommon(i),'ButtonDownFcn', @(src,evt)(trackButtonDown(trackID)));
    end
end

%% Click handling

function trackButtonDown(trackID)
    global Figures CellTracks
    selType = get(Figures.tree.handle, 'SelectionType');
    if ( strcmpi(selType,'alt') )
        Backtracker.SelectTrackingCell(trackID,CellTracks(trackID).startTime);
    end
end

%% Tree traversal and ordering functions

function [sortedTracks bFamHasPheno] = simpleTraverseTree(trackID, xVal, trackMap, trackHeights)
    global CellTracks CellPhenotypes
    
    bFamHasPheno = false(length(CellPhenotypes.descriptions),1);
    phenoType = Tracks.GetTrackPhenotype(trackID);
    if ( phenoType > 0 )
        bFamHasPheno(phenoType) = true;
    end
    
    if ( isempty(CellTracks(trackID).childrenTracks) )
        startTime = CellTracks(trackID).startTime;
        endTime = CellTracks(trackID).endTime + 1;
        
        sortedTracks = trackID;
        trackMap(trackID) = struct('xCenter',{xVal} ,'xBox',{[xVal-0.5 xVal+0.5]}, 'yBox',[startTime endTime]);
        return;
    end
    
    leftChildID = CellTracks(trackID).childrenTracks(1);
    rightChildID = CellTracks(trackID).childrenTracks(2);
    if ( trackHeights(leftChildID) < trackHeights(rightChildID) )
        leftChildID = CellTracks(trackID).childrenTracks(2);
        rightChildID = CellTracks(trackID).childrenTracks(1);
    end
    
    [leftTracks bLeftChildHasPheno] = simpleTraverseTree(leftChildID, xVal, trackMap, trackHeights);
    xRightVal = trackMap(leftChildID).xBox(2) + 0.5;
    
    [rightTracks bRightChildHasPheno] = simpleTraverseTree(rightChildID, xRightVal, trackMap, trackHeights);
    bFamHasPheno = (bFamHasPheno | bLeftChildHasPheno | bRightChildHasPheno);
    
    xCenter = mean([trackMap(leftChildID).xCenter trackMap(rightChildID).xCenter]);
    
    xMin = min(trackMap(leftChildID).xBox(1), trackMap(rightChildID).xBox(1));
    xMax = max(trackMap(leftChildID).xBox(2), trackMap(rightChildID).xBox(2));
    
    yMin = CellTracks(trackID).startTime;
    yMax = max(trackMap(leftChildID).yBox(2), trackMap(rightChildID).yBox(2));
    
    sortedTracks = [trackID leftTracks rightTracks];
    trackMap(trackID) = struct('xCenter',{xCenter} ,'xBox',{[xMin xMax]}, 'yBox',[yMin yMax]);
end
