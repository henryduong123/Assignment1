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
fileName = [CONSTANTS.rootImageFolder CONSTANTS.datasetName '_t' num2str(Figures.time,'%03d') '.TIF'];
[img colrMap] = imread(fileName);
xl=xlim;
yl=ylim;

%adjust the image display

hold off;
imagesc(img);
set(gca,'Position',[.01 .01 .98 .98],'uicontextmenu',Figures.cells.contextMenuHandle);
axis off;
if xl(1)~=0 && xl(2)~=1
    xlim(xl);
    ylim(yl);
end
colormap(gray);
hold all;


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
        
        %draw outline
        plot(CellHulls(curHullID).points(:,1),...
            CellHulls(curHullID).points(:,2),...
            'Color',            edgeColor,...
            'UserData',         curTrackID,...
            'uicontextmenu',    Figures.cells.contextMenuHandle);
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
end
end
