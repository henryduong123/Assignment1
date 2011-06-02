%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
%     This file is part of LEVer.exe
%     (C) 2011 Andrew Cohen, Eric Wait and Mark Winter
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function DrawCells()
%This will display the image with the cells outlined and labeled unless the
%labels are turned off, in which case only the image is displayed
%All the cells that are part of the family will be have circular labels and
%will be more boldly colored, others will be with square labels and be
%slightly grayed out


global CellFamilies CellTracks CellHulls HashedCells Figures CONSTANTS

if(isempty(CellFamilies(Figures.tree.familyID).tracks)),return,end

figure(Figures.cells.handle);
set(Figures.cells.timeLabel,'String',['Time: ' num2str(Figures.time)]);
%read in image
fileName = [CONSTANTS.rootImageFolder CONSTANTS.datasetName '_t' SignificantDigits(Figures.time) '.TIF'];
if exist(fileName,'file')
    [img colrMap] = imread(fileName);
else
    img=zeros(CONSTANTS.imageSize);
end
    
xl=xlim;
yl=ylim;

%adjust the image display

hold off;
im = imagesc(img);
set(im,'uicontextmenu',Figures.cells.contextMenuHandle);
set(gca,'Position',[.01 .01 .98 .98],'uicontextmenu',Figures.cells.contextMenuHandle);
axis off;
if xl(1)~=0 && xl(2)~=1
    xlim(xl);
    ylim(yl);
end
colormap(gray);
hold all;

siblingsAlreadyDrawn = [];

%draw Image or not
if(strcmp(get(Figures.cells.menuHandles.imageMenu, 'Checked'),'off'))
    set(im,'Visible','off');
end

%draw labels if turned on
if(strcmp(get(Figures.cells.menuHandles.labelsMenu, 'Checked'),'on'))
    for i=1:length(HashedCells{Figures.time})
        curHullID = HashedCells{Figures.time}(i).hullID;
        curTrackID = HashedCells{Figures.time}(i).trackID;
        
        xLabelCorner = max(CellHulls(curHullID).points(:,1));
        yLabelCorner = max(CellHulls(curHullID).points(:,2));
        fontSize = 8;
        switch length(num2str(curTrackID))
            case 1
                shapeSize=8;
            case 2
                shapeSize=11;
            case 3
                shapeSize=15;
            otherwise
                shapeSize=17;
                fontSize = 7;
        end
        
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
        if(~isempty(CellTracks(curTrackID).timeOfDeath))
            backgroundColor = 'k';
            edgeColor = 'r';
            textColor = 'r';
        end
        
        %draw connection to sibling 
        if(strcmp(get(Figures.cells.menuHandles.siblingsMenu, 'Checked'),'on'))
            %if the cell is on the current tree or already drawn
            if(Figures.tree.familyID == CellTracks(curTrackID).familyID && isempty(find(siblingsAlreadyDrawn==curTrackID, 1)))
                siblingsAlreadyDrawn = [siblingsAlreadyDrawn drawSiblingsLine(curTrackID,curHullID)];
            end
        end
        
        drawWidth = 1;
        drawStyle = '-';
        if ( any(Figures.cells.selectedHulls == curHullID) )
            drawWidth = 1.5;
            drawStyle = '--';
        end
            
        %draw outline
        plot(CellHulls(curHullID).points(:,1),...
            CellHulls(curHullID).points(:,2),...
            'Color',            edgeColor,...
            'UserData',         curTrackID,...
            'uicontextmenu',    Figures.cells.contextMenuHandle,...
            'LineStyle',        drawStyle,...
            'LineWidth',        drawWidth);
        %draw label
        plot(xLabelCorner,...
            yLabelCorner,...
            shape,              ...
            'MarkerFaceColor',  backgroundColor,...
            'MarkerEdgeColor',  edgeColor,...
            'MarkerSize',       shapeSize,...
            'UserData',         curTrackID,...
            'uicontextmenu',    Figures.cells.contextMenuHandle);
        text(xLabelCorner,          ...
            yLabelCorner,           ...
            num2str(curTrackID),...
            'Color',                textColor,...
            'FontWeight',           fontWeight,...
            'FontSize',             fontSize,...
            'HorizontalAlignment',  'center',...
            'UserData',             curTrackID,...
            'uicontextmenu',        Figures.cells.contextMenuHandle);
    end
elseif(strcmp(get(Figures.cells.menuHandles.siblingsMenu, 'Checked'),'on'))
    %just draw sibling lines
    for i=1:length(HashedCells{Figures.time})
        curHullID = HashedCells{Figures.time}(i).hullID;
        curTrackID = HashedCells{Figures.time}(i).trackID;
        
        %if the cell is on the current tree or already drawn
        if(Figures.tree.familyID == CellTracks(curTrackID).familyID && isempty(find(siblingsAlreadyDrawn==curTrackID, 1)))
            siblingsAlreadyDrawn = [siblingsAlreadyDrawn drawSiblingsLine(curTrackID,curHullID)];
        end
    end
end

Figures.cells.axesHandle = gca;
end

function tracksDrawn = drawSiblingsLine(trackID,hullID)
global Figures CellTracks CellHulls HashedCells

tracksDrawn = [];
siblingID = CellTracks(trackID).siblingTrack;
parentID = CellTracks(trackID).parentTrack;

if(isempty(siblingID)),return,end

tracksDrawn = [trackID siblingID];

siblingHullID = [HashedCells{Figures.time}.trackID] == siblingID;
siblingHullID = [HashedCells{Figures.time}(siblingHullID).hullID];

if(isempty(siblingHullID)),return,end

plot([CellHulls(hullID).centerOfMass(2) CellHulls(siblingHullID).centerOfMass(2)],...
    [CellHulls(hullID).centerOfMass(1) CellHulls(siblingHullID).centerOfMass(1)],...
    'Color',            CellTracks(parentID).color.background,...
    'UserData',         trackID,...
    'uicontextmenu',    Figures.cells.contextMenuHandle,...
    'Tag',              'SiblingRelationship');

% set(Figures.cells.removeMenu,'Visible','on');
end
