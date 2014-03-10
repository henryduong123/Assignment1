function DrawCells()
    global bDirty CONSTANTS Figures HashedCells
    
    filename = Helper.GetFullImagePath(Figures.time);
    if (exist(filename,'file')==2)
        img = Helper.LoadIntensityImage(filename);
    else
        img = zeros(CONSTANTS.imageSize);
    end

    curAx = get(Figures.cells.handle, 'CurrentAxes');
    if ( isempty(curAx) )
        curAx = axes('Parent',Figures.cells.handle);
        set(Figures.cells.handle, 'CurrentAxes',curAx);
        
        xl = [1 CONSTANTS.imageSize(2)];
        yl = [1 CONSTANTS.imageSize(1)];
    else
        xl = xlim(curAx);
        yl = ylim(curAx);
    end
    
    hold(curAx, 'off');
    hIm = imagesc(img, 'Parent',curAx);
    
    set(curAx,'Position',[.01 .01 .98 .98]);
    axis(curAx,'off');
    
    colormap(curAx, gray);
    hold(curAx,'all');
    
    % Draw staining info on the last frame
    if ( Figures.time == length(HashedCells) )
        drawStainInfo(curAx);
    end
    
    % Draw cells on edited families
    drawFamTracks(curAx, Figures.time);

    hold(curAx, 'off');
    
    xlim(curAx,xl);
    ylim(curAx,yl);
    
    if ( bDirty )
        set(Figures.cells.handle, 'Name',[CONSTANTS.datasetName ' Cells *']);
    else
        set(Figures.cells.handle, 'Name',[CONSTANTS.datasetName ' Cells']);
    end
end

function drawFamTracks(hAx, time)
    global Figures CellFamilies CellTracks CellHulls EditFamIdx BackTrackIdx
    
    % Draw edited-family tracks and backtracking tracks
    famTracks = [CellFamilies(EditFamIdx).tracks];
    famTracks = [famTracks BackTrackIdx];
    
    bPastStart = ([CellTracks(famTracks).startTime] <= time);
    bBeforeEnd = ([CellTracks(famTracks).endTime] >= time);
    bInTracks = (bPastStart & bBeforeEnd);
    
    selectedTrackID = Backtracker.GetSelectedTrackID();
    
    if ( any(bInTracks) )
        inTracks = famTracks(bInTracks);
        for i=1:length(inTracks)
            hullID = Tracks.GetHullID(time, inTracks(i));
            if ( hullID == 0 )
                continue;
            end
            
            trackColor = CellTracks(inTracks(i)).color.background;
            textColor = CellTracks(inTracks(i)).color.text;
            
            hullPoints = CellHulls(hullID).points;
            
            % Plot Outline
            if ( inTracks(i) == selectedTrackID )
                plot(hAx, hullPoints(:,1), hullPoints(:,2), '--', 'Color',trackColor, 'LineWidth',1.5);
            else
                plot(hAx, hullPoints(:,1), hullPoints(:,2), '-', 'Color',trackColor);
            end
            
            
            drawString = num2str(inTracks(i));
            labelCorner = max(hullPoints,[],1);
            [fontSize shapeSize] = UI.GetFontShapeSizes(length(drawString));
            
            % Plot Label
            plot(hAx, labelCorner(1), labelCorner(2), 'o', 'MarkerEdgeColor',trackColor, 'MarkerFaceColor',trackColor,'MarkerSize',shapeSize);
            text(labelCorner(1), labelCorner(2), drawString, 'Parent',hAx, 'Color',textColor, 'FontSize',fontSize, 'HorizontalAlignment','center');
        end
    end
end

function drawStainInfo(hAx)
    global stains stainColors
    
    drawCircleSize = 6;
    
    hold(hAx, 'on');
    for i=1:length(stains)
        x = stains(i).point(1);
        y = stains(i).point(2);
        
        circleColor = stainColors(stains(i).stainID).color;
        
        h = rectangle('Position', [x-drawCircleSize/2 y-drawCircleSize/2 drawCircleSize drawCircleSize], 'Curvature',[1 1], 'EdgeColor',circleColor,'FaceColor',circleColor, 'Parent',hAx);
    end
end
