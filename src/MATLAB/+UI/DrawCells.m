% DrawCells.m - 
% This will display the image with the cells outlined and labeled unless the
% labels are turned off, in which case only the image is displayed
% All the cells that are part of the family will be have circular labels and
% will be more boldly colored, others will be with square labels and be
% slightly grayed out

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
%     Copyright 2011 Andrew Cohen, Eric Wait and Mark Winter
%
%     This file is part of LEVer - the tool for stem cell lineaging. See
%     https://pantherfile.uwm.edu/cohena/www/LEVer.html for details
% 
%     LEVer is free software: you can redistribute it and/or modify
%     it under the terms of the GNU General Public License as published by
%     the Free Software Foundation, either version 3 of the License, or
%     (at your option) any later version.
% 
%     LEVer is distributed in the hope that it will be useful,
%     but WITHOUT ANY WARRANTY; without even the implied warranty of
%     MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
%     GNU General Public License for more details.
% 
%     You should have received a copy of the GNU General Public License
%     along with LEVer in file "gnu gpl v3.txt".  If not, see 
%     <http://www.gnu.org/licenses/>.
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function DrawCells()

global CellFamilies CellTracks CellHulls HashedCells Figures CONSTANTS MitosisEditStruct

% figure(Figures.cells.handle);
timeLabel = ['Time: ' num2str(Figures.time)];
set(Figures.cells.timeLabel,'String',timeLabel);

[localLabels, revLocalLabels] = UI.GetLocalTreeLabels(Figures.tree.familyID);

% Missing Cells Counter
missingCells = UI.CellCountDifference();
if strcmp(get(Figures.cells.menuHandles.missingCellsMenu, 'Checked'),'on')
    if(missingCells == 0)   % no missing cells = green
        set(Figures.cells.cellCountLabel,'Visible', 'on',...
            'ForegroundColor',[0 0.4 0],...
            'FontSize', 8, 'String', ['Missing Cells: ' num2str(missingCells)]);
    else % Missing Cells turns red
        set(Figures.cells.cellCountLabel,'Visible', 'on',...
            'ForegroundColor',[1 0 0], ...
            'FontSize', 9, 'String', ['Missing Cells: ' num2str(missingCells)]);
    end
else
    set(Figures.cells.cellCountLabel,'Visible', 'off');
end

%read in image
img = Helper.LoadChannelIntensityImage(Figures.time,Figures.chanIdx);
if ( isempty(img) )
    img = zeros(CONSTANTS.imageSize);
end

imMax = max(img(:));
img = mat2gray(img,[0 imMax]);

chanLabel = sprintf('Channel: %d', Figures.chanIdx);
set(Figures.cells.chanLabel,'String',chanLabel);

curAx = get(Figures.cells.handle, 'CurrentAxes');
if ( isempty(curAx) )
    curAx = axes('Parent',Figures.cells.handle);
    set(Figures.cells.handle, 'CurrentAxes',curAx);
end

xl=xlim(curAx);
yl=ylim(curAx);

%adjust the image display

hold(curAx, 'off');
im = imagesc(img, 'Parent',curAx, [0 1]);
set(im,'uicontextmenu',Figures.cells.contextMenuHandle);
set(im, 'ButtonDownFcn',( @(src,evt) (UI.FigureCellDown(src,evt, -1))));

set(curAx,'Position',[.01 .01 .98 .98], 'uicontextmenu',Figures.cells.contextMenuHandle, 'SortMethod','childorder');
axis(curAx,'off');

% Force original zoom level to be the full image before we "zoom in"
zoom(Figures.cells.handle, 'reset');

if xl(1)~=0 && xl(2)~=1
    xlim(curAx,xl);
    ylim(curAx,yl);
end

xl=xlim(curAx);
yl=ylim(curAx);

colormap(curAx, gray);
hold(curAx,'all');

siblingsAlreadyDrawn = [];

%draw Image or not
if(strcmp(get(Figures.cells.menuHandles.imageMenu, 'Checked'),'off'))
    set(im,'Visible','off');
end

bDrawLabels = true;

drawHullFilter = [];
if ( strcmpi(Figures.cells.editMode, 'mitosis') )
    % Filter so we only draw family "mitosis" hulls when editing
    bDrawLabels = 0;
    drawHullFilter = arrayfun(@(x)(CellTracks(x).hulls(CellTracks(x).hulls~=0)),...
        CellFamilies(Figures.tree.familyID).tracks, 'UniformOutput',0);
    drawHullFilter = [drawHullFilter{:}];
end

if ( (Figures.time == length(HashedCells)) )
    drawStainInfo(curAx);
end
        
%draw labels if turned on
Figures.cells.labelHandles = [];
bShowOffTreeLabels = strcmp(get(Figures.cells.menuHandles.treeLabelsOn, 'Checked'),'on');
if(strcmp(get(Figures.cells.menuHandles.labelsMenu, 'Checked'),'on'))
    for i=1:length(HashedCells{Figures.time})
           
        curHullID = HashedCells{Figures.time}(i).hullID;
        curTrackID = HashedCells{Figures.time}(i).trackID;

        if ( ~isempty(drawHullFilter) && ~any(curHullID == drawHullFilter ) )
            continue;
        end
        
        if ( ~checkCOMLims(curHullID, xl, yl) )
            continue;
        end

%         if(Figures.cells.showInterior)
%             drawString = [num2str(curTrackID) ' / ' num2str(curHullID)];
%         else
%             drawString = num2str(curTrackID);
%         end
        if isKey(localLabels, curTrackID)
            labelStr = localLabels(curTrackID);
        else
            labelStr = num2str(curTrackID);
        end
        
        if(Figures.cells.showInterior)
            drawString = [labelStr ' / ' num2str(curHullID)];
        else
            drawString = labelStr;
        end
        
        %draw connection to sibling 
        if(strcmp(get(Figures.cells.menuHandles.siblingsMenu, 'Checked'),'on') ||...
            CellTracks(curTrackID).startTime == Figures.time)
            %draw if the hull was part of a mitosis on this frame
            %if the cell is on the current tree or already drawn
            if( Figures.tree.familyID == CellTracks(curTrackID).familyID && ~any(siblingsAlreadyDrawn==curTrackID) )
                siblingsAlreadyDrawn = [siblingsAlreadyDrawn drawSiblingsLine(curAx, curTrackID, curHullID)];
            end
        end
        
        % I'm not sure if I still need these lines
        drawWidth = 2;
        drawStyle = '-';
        if ( any(Figures.cells.selectedHulls == curHullID) )
            drawWidth = 2.5;
            drawStyle = '--';
        end
        % end of not sure
        
        colorStruct = UI.GetCellDrawProps(curTrackID, curHullID, drawString);
        
        if(Figures.cells.showInterior)
            [r c] = ind2sub(CONSTANTS.imageSize, CellHulls(curHullID).indexPixels);
            plot(curAx, c, r, '.', 'Color',colorStruct.edge);
        end
        
        %draw outline
        plot(curAx, CellHulls(curHullID).points(:,1),...
            CellHulls(curHullID).points(:,2),...
            'Color',            colorStruct.edge,...
            'UserData',         curTrackID,...
            'uicontextmenu',    Figures.cells.contextMenuHandle,...
            'ButtonDownFcn',( @(src,evt) (UI.FigureCellDown(src,evt,curHullID))),...
            'LineStyle',        colorStruct.edgeStyle,...
            'LineWidth',        2);
        
        % Plot light-blue border if frozen track
        if ( Helper.CheckTreeFrozen(curTrackID) )
            if (Figures.tree.familyID == CellTracks(curTrackID).familyID )
                drawExpandedHull(curAx, CellHulls(curHullID).points, 1, ...
                    [0.75 0.85 1.0],colorStruct.edgeStyle,colorStruct.edgeWidth);
            else
                plot(curAx, CellHulls(curHullID).points(:,1),...
                    CellHulls(curHullID).points(:,2),...
                    'Color',            [0.75 0.85 1.0],...
                    'UserData',         curTrackID,...
                    'uicontextmenu',    Figures.cells.contextMenuHandle,...
                    'ButtonDownFcn',( @(src,evt) (UI.FigureCellDown(src,evt,curHullID))),...
                    'LineStyle',        colorStruct.edgeStyle,...
                    'LineWidth',        colorStruct.edgeWidth);
            end
        end
        
        % Show bright selected cell outline
        if ( ~isempty(MitosisEditStruct) && isfield(MitosisEditStruct,'selectedTrackID') )
            if ( ~isempty(MitosisEditStruct.selectedTrackID) && (MitosisEditStruct.selectedTrackID == curTrackID) )
                hullPoints = CellHulls(curHullID).points;
                if ( size(hullPoints,1) == 1 )
                    drawExpandedHull(curAx, hullPoints, CONSTANTS.pointClickMargin, 'r','--',2);
                else
                    drawExpandedHull(curAx, hullPoints, 1, 'r','--',2);
                end
            end
        end
        
        %draw label
        if( bDrawLabels )%don't draw labels if dragging a mitosis
            roots = Families.GetFamilyRoots(curTrackID);
            bOnFamily = any(Figures.tree.familyID == [CellTracks(roots).familyID]);
            if ( bShowOffTreeLabels || bOnFamily )
                magPoints = ((CellHulls(curHullID).points(:,1)) +((CellHulls(curHullID).points(:,2))));
                
                % attach label to point with highest Manhattan distance
                % (x+y)
                [~, idx] = max(magPoints);
                
                xLabelCorner = CellHulls(curHullID).points(idx,1);
                yLabelCorner = CellHulls(curHullID).points(idx,2);
                % end new labels
                
%               % old labels
%                 xLabelCorner = max(CellHulls(curHullID).points(:,1));
%                 yLabelCorner = max(CellHulls(curHullID).points(:,2));                
                % draw label in center of mass
%                 xLabelCorner = CellHulls(curHullID).centerOfMass(2);
%                 yLabelCorner = CellHulls(curHullID).centerOfMass(1);
                % end
                
                [textHandle, bgHandle] = UI.DrawCellLabel(curAx, drawString, xLabelCorner, yLabelCorner, colorStruct);
                
                set(textHandle, 'UserData',curTrackID,...
                    'ButtonDownFcn', (@(src,evt) (UI.FigureCellDown(src,evt,curHullID))),...
                    'uicontextmenu', Figures.cells.contextMenuHandle);
                
                set(bgHandle, 'UserData',curTrackID,...
                    'ButtonDownFcn',( @(src,evt) (UI.FigureCellDown(src,evt,curHullID))),...
                    'uicontextmenu', Figures.cells.contextMenuHandle);
            end
        end
    end
elseif(strcmp(get(Figures.cells.menuHandles.siblingsMenu, 'Checked'),'on'))
    %just draw sibling lines
    for i=1:length(HashedCells{Figures.time})
        curHullID = HashedCells{Figures.time}(i).hullID;
        curTrackID = HashedCells{Figures.time}(i).trackID;
        
        %if the cell is on the current tree or already drawn
        if(Figures.tree.familyID == CellTracks(curTrackID).familyID && isempty(find(siblingsAlreadyDrawn==curTrackID, 1)))
            siblingsAlreadyDrawn = [siblingsAlreadyDrawn drawSiblingsLine(curAx, curTrackID,curHullID)];
        end
    end
end


Figures.cells.axesHandle = curAx;

drawnow();
end

function drawExpandedHull(curAx, hullPoints, expandRadius, color,style,width)
expandPoints = Helper.MakeExpandedCVHull(hullPoints, expandRadius);
if ( isempty(expandPoints) )
    rectangle('Parent',curAx, 'Curvature',[1 1], 'EdgeColor',color, 'LineStyle',style ,'LineWidth',width,...
        'Position',[hullPoints(1,1)-expandRadius hullPoints(1,2)-expandRadius 2*expandRadius 2*expandRadius]);
    return;
end

plot(curAx, expandPoints(:,1), expandPoints(:,2), style,'Color',color, 'LineWidth',width);
end

function tracksDrawn = drawSiblingsLine(curAx, trackID,hullID)
global Figures CellTracks CellHulls HashedCells

tracksDrawn = [];
siblingID = CellTracks(trackID).siblingTrack;
parentID = CellTracks(trackID).parentTrack;

if(isempty(siblingID)),return,end

tracksDrawn = [trackID siblingID];

siblingHullID = [HashedCells{Figures.time}.trackID] == siblingID;
siblingHullID = [HashedCells{Figures.time}(siblingHullID).hullID];

if(isempty(siblingHullID)),return,end

plot(curAx, [CellHulls(hullID).centerOfMass(2) CellHulls(siblingHullID).centerOfMass(2)],...
    [CellHulls(hullID).centerOfMass(1) CellHulls(siblingHullID).centerOfMass(1)],...
    'Color',            CellTracks(parentID).color.background,...
    'UserData',         trackID,...
    'uicontextmenu',    Figures.cells.contextMenuHandle,...
    'Tag',              'SiblingRelationship');
end

function drawStainInfo(hAx)
    global stains stainColors
    
    if ( isempty(stainColors) )
        return;
    end
    
    drawCircleSize = 6;
    
    hold(hAx, 'on');
    for i=1:length(stains)
        x = stains(i).point(1);
        y = stains(i).point(2);
        
        circleColor = stainColors(stains(i).stainID).color;
        
        h = rectangle('Position', [x-drawCircleSize/2 y-drawCircleSize/2 drawCircleSize drawCircleSize], 'Curvature',[1 1], 'EdgeColor',circleColor,'FaceColor',circleColor, 'Parent',hAx);
    end
end

function bInLims = checkCOMLims(hullID, xlims, ylims)
    global CellHulls Figures
    
    bInLims = 0;
    
    if ( CellHulls(hullID).centerOfMass(2) < (xlims(1)-10) || CellHulls(hullID).centerOfMass(2) > (xlims(2)+10) )
        return;
    end
    
    if ( CellHulls(hullID).centerOfMass(1) < (ylims(1)-10) || CellHulls(hullID).centerOfMass(1) > (ylims(2)+10) )
        return;
    end
    
    bInLims = 1;
end
