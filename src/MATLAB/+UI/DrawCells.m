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

global CellFamilies CellTracks CellHulls HashedCells Figures CONSTANTS

if(isempty(CellFamilies(Figures.tree.familyID).tracks)),return,end

% figure(Figures.cells.handle);
set(Figures.cells.timeLabel,'String',['Time: ' num2str(Figures.time)]);
%read in image
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
end

xl=xlim(curAx);
yl=ylim(curAx);

%adjust the image display

hold(curAx, 'off');
im = imagesc(img, 'Parent',curAx);
set(im,'uicontextmenu',Figures.cells.contextMenuHandle);
set(im, 'ButtonDownFcn',( @(src,evt) (UI.FigureCellDown(src,evt, -1))));

set(curAx,'Position',[.01 .01 .98 .98],'uicontextmenu',Figures.cells.contextMenuHandle);
axis(curAx,'off');
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

%draw labels if turned on
Figures.cells.labelHandles = [];
if(strcmp(get(Figures.cells.menuHandles.labelsMenu, 'Checked'),'on'))
    for i=1:length(HashedCells{Figures.time})
           
        curHullID = HashedCells{Figures.time}(i).hullID;
        curTrackID = HashedCells{Figures.time}(i).trackID;
        
        %if dragging a mitosis, only show the siblings: Draws faster
        %and makes it easier to follow what is changing
        if(Figures.tree.movingMitosis)
            if(Figures.tree.movingMitosis ~= curTrackID)
                continue;
            end
        end
        
        xLabelCorner = max(CellHulls(curHullID).points(:,1));
        yLabelCorner = max(CellHulls(curHullID).points(:,2));
        
        if(Figures.cells.showInterior)
            drawString = [num2str(curTrackID) ' / ' num2str(curHullID)];
        else
            drawString = num2str(curTrackID);
        end
        
        [fontSize shapeSize] = UI.GetFontShapeSizes(length(drawString));
        
        %if the cell is on the current tree
        if(Figures.tree.familyID == CellTracks(curTrackID).familyID)
            backgroundColor = CellTracks(curTrackID).color.background;
            edgeColor = CellTracks(curTrackID).color.background;
            textColor = CellTracks(curTrackID).color.text;
            fontWeight = 'bold';
            shape = 'o';
        else
            %if the cell is not on the current tree
            backgroundColor = CellTracks(curTrackID).color.backgroundDark;
            edgeColor = CellTracks(curTrackID).color.backgroundDark;
            textColor = CellTracks(curTrackID).color.text * 0.5;
            fontWeight = 'normal';
            shape = 'square';
            fontSize = fontSize * 0.9;
        end
        
        %see if the cell is dead
        if(~isempty(Tracks.GetTimeOfDeath(curTrackID)))
            backgroundColor = 'k';
            edgeColor = 'r';
            textColor = 'r';
        end
        
        %draw connection to sibling 
        if(strcmp(get(Figures.cells.menuHandles.siblingsMenu, 'Checked'),'on') ||...
            CellTracks(curTrackID).startTime == Figures.time)
            %draw if the hull was part of a mitosis on this frame
            %if the cell is on the current tree or already drawn
            if(Figures.tree.familyID == CellTracks(curTrackID).familyID && isempty(find(siblingsAlreadyDrawn==curTrackID, 1)))
                siblingsAlreadyDrawn = [siblingsAlreadyDrawn drawSiblingsLine(curAx, curTrackID,curHullID)];
            end
        end
        
        drawWidth = 1;
        drawStyle = '-';
        if ( any(Figures.cells.selectedHulls == curHullID) )
            drawWidth = 1.5;
            drawStyle = '--';
        end
        
        if ( ~checkCOMLims(curHullID, xl, yl) )
            continue;
        end
          
        if(Figures.cells.showInterior)
            [r c] = ind2sub(CONSTANTS.imageSize, CellHulls(curHullID).indexPixels);
            plot(curAx, c, r, '.', 'Color',edgeColor);
        end
        %draw outline
        plot(curAx, CellHulls(curHullID).points(:,1),...
            CellHulls(curHullID).points(:,2),...
            'Color',            edgeColor,...
            'UserData',         curTrackID,...
            'uicontextmenu',    Figures.cells.contextMenuHandle,...
            'ButtonDownFcn',( @(src,evt) (UI.FigureCellDown(src,evt,curHullID))),...
            'LineStyle',        drawStyle,...
            'LineWidth',        drawWidth);
        
        %draw label
        if(isempty(Figures.tree.movingMitosis)) %don't draw labels if dragging a mitosis
            labelBGColor = edgeColor;
            if ( ~Figures.cells.showInterior )
                labelBGColor = 'none';
                
                labelHandle = plot(curAx, xLabelCorner,...
                                yLabelCorner,...
                                shape,              ...
                                'MarkerFaceColor',  backgroundColor,...
                                'MarkerEdgeColor',  edgeColor,...
                                'MarkerSize',       shapeSize,...
                                'UserData',         curTrackID,...
                                'ButtonDownFcn',( @(src,evt) (UI.FigureCellDown(src,evt,curHullID))),...
                                'uicontextmenu',    Figures.cells.contextMenuHandle);
            end
            
            labelTextHandle = text(xLabelCorner,          ...
                                yLabelCorner,           ...
                                drawString,...
                                'Parent',               curAx,...
                                'Color',                textColor,...
                                'BackgroundColor',      labelBGColor,...
                                'FontWeight',           fontWeight,...
                                'FontSize',             fontSize,...
                                'HorizontalAlignment',  'center',...
                                'UserData',             curTrackID,...
                                'ButtonDownFcn',( @(src,evt) (UI.FigureCellDown(src,evt,curHullID))),...
                                'uicontextmenu',        Figures.cells.contextMenuHandle);
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
if(~isempty(Figures.cells.PostDrawHookOnce))
    for i=1:length(Figures.cells.PostDrawHookOnce)
        hook = Figures.cells.PostDrawHookOnce{i};
        hook(curAx);
    end       
    Figures.cells.PostDrawHookOnce = {};
end
drawnow();
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
