function DrawTree(familyID)
%This will draw the family tree of the given family.

%--Eric Wait

global CellFamilies HashedCells Figures

if(isempty(CellFamilies(familyID).tracks)),return,end

%let the user know that this might take a while
set(Figures.tree.handle,'Pointer','watch');
set(Figures.cells.handle,'Pointer','watch');

Figures.tree.familyID = familyID;

trackID = CellFamilies(familyID).tracks(1);

figure(Figures.tree.handle);
delete(gca);
    
set(gca,...
    'YDir',     'reverse',...
    'YLim',     [0 length(HashedCells)],...
    'Position', [.06 .06 .90 .90],...
    'XColor',   'w',...
    'XTick',    []);
hold on

[xMin xCenter xMax] = traverseTree(trackID,0);

set(gca,...
    'XLim',     [xMin-1 xMax+1]);
Figures.tree.axesHandle = gca;
hold off
UpdateTimeIndicatorLine();

%let the user know that the drawing is done
set(Figures.tree.handle,'Pointer','arrow');
set(Figures.cells.handle,'Pointer','arrow');
end

function [xMin xCenter xMax] = traverseTree(trackID,initXmin)
global CellTracks
if(~isempty(CellTracks(trackID).childrenTracks))
    [child1Xmin child1Xcenter child1Xmax] = traverseTree(CellTracks(trackID).childrenTracks(1),initXmin);
    [child2Xmin child2Xcenter child2Xmax] = traverseTree(CellTracks(trackID).childrenTracks(2),child1Xmax+1);
    xMin = min(child1Xmin,child2Xmin);
    xMax = max(child1Xmax,child2Xmax);
    if(child1Xcenter < child2Xcenter)
        drawHorizontalEdge(child1Xcenter,child2Xcenter,CellTracks(trackID).endTime+1,trackID);
        xCenter = (child2Xcenter-child1Xcenter)/2 + child1Xcenter;
    else
        drawHorizontalEdge(child2Xcenter,child1Xcenter,CellTracks(trackID).endTime+1,trackID);
        xCenter = (child1Xcenter-child2Xcenter)/2 + child2Xcenter;
    end
    drawVerticalEdge(trackID,xCenter);
else
    %This is when the edge is for a leaf node
    drawVerticalEdge(trackID,initXmin);
    xMin = initXmin;
    xCenter = initXmin;
    xMax = initXmin;
end
end

function drawHorizontalEdge(xMin,xMax,y,trackID)
global Figures
plot([xMin xMax],[y y],'-k','UserData',trackID,'uicontextmenu',Figures.tree.contextMenuHandle);
%Place the line behind all other elements already graphed
h = get(gca,'child');
h = h([2:end, 1]);
set(gca, 'child', h);
end

function drawVerticalEdge(trackID,xVal)
global CellTracks Figures

%draw circle for node
FontSize = 8;
switch length(num2str(trackID))
    case 1
        circleSize=10;
    case 2
        circleSize=12;
    case 3
        circleSize=14;
    otherwise
        circleSize=16;
        FontSize = 7;
end

yMin = CellTracks(trackID).startTime;
if(isempty(CellTracks(trackID).timeOfDeath))
    %draw vertical line to represent edge length
    plot([xVal xVal],[yMin CellTracks(trackID).endTime+1],...
        '-k','UserData',trackID,'uicontextmenu',Figures.tree.contextMenuHandle);
    
    color = CellTracks(trackID).color;
    plot(xVal,yMin,'o',...
        'MarkerFaceColor',  color.background,...
        'MarkerEdgeColor',  color.background,...
        'MarkerSize',       circleSize,...
        'UserData',         trackID,...
        'uicontextmenu',    Figures.tree.contextMenuHandle);
    text(xVal,yMin,num2str(trackID),...
        'HorizontalAlignment',  'center',...
        'FontSize',             FontSize,...
        'color',                color.text,...
        'UserData',             trackID,...
        'uicontextmenu',        Figures.tree.contextMenuHandle);
else
    yMin2 = CellTracks(trackID).timeOfDeath;
    plot([xVal xVal],[yMin yMin2],...
        '-k','UserData',trackID);
    plot([xVal xVal],[yMin2 CellTracks(trackID).endTime+1],...
        '--k','UserData',trackID,'uicontextmenu',Figures.tree.contextMenuHandle);
    plot(xVal,yMin2,'rx','UserData',trackID);
    plot(xVal,yMin,'o',...
        'MarkerFaceColor',  'k',...
        'MarkerEdgeColor',  'r',...
        'MarkerSize',       circleSize,...
        'UserData',         trackID,...
        'uicontextmenu',    Figures.tree.contextMenuHandle);
    text(xVal,yMin,num2str(trackID),...
        'HorizontalAlignment',  'center',...
        'FontSize',             FontSize,...
        'color',                'r',...
        'UserData',             trackID,...
        'uicontextmenu',        Figures.tree.contextMenuHandle);
end
end

