%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
%     This file is part of LEVer.exe
%     (C) 2011 Andrew Cohen, Eric Wait and Mark Winter
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function ExportTree(src, evt)
%This will draw the family tree of the given family. This is designed
% for exporting tree with no numeric labels for publication purpose


global CellFamilies HashedCells Figures CONSTANTS CellTracks CellPhenotypes  
figure
set(gcf,'name',CONSTANTS.datasetName)
set(gcf,'numbertitle','off')
set(gcf,'color','w')
familyID=Figures.tree.familyID;
if(isfield(CellTracks,'phenotype'))     
    phenoScratch.phenoColors = hsv(length(CellPhenotypes.contextMenuID));
    phenoScratch.phenoLegendSet = zeros(length(CellPhenotypes.contextMenuID),1);
else
   phenoScratch.phenoColors = [];
   phenoScratch.phenoLegendSet = [];    
end

if(~isfield(CONSTANTS,'timeResolution'))
    CONSTANTS.timeResolution = 10;
end

if(isempty(CellFamilies(familyID).tracks)),return,end

trackID = CellFamilies(familyID).tracks(1);

overAxes = axes;
    
set(overAxes,...
    'YDir',     'reverse',...
    'YLim',     [0 length(HashedCells)],...
    'Position', [.06 .06 .90 .90],...
    'XColor',   'w',...
    'XTick',    [],...
    'Box',      'off');
% ylabel('Time (Frames)');
hold on

[xMin xCenter xMax phenoScratch] = traverseTree(trackID,0,phenoScratch);

% set(underAxes,...
%     'XLim',     [xMin-1 xMax+1]);
set(overAxes,...
    'XLim',     [xMin-1 xMax+1]);
Figures.tree.axesHandle = overAxes;
UpdateTimeIndicatorLine();
% gObjects = get(Figures.tree.axesHandle,'children');
% parfor i=1:length(gObjects)
%     set(get(get(gObjects(i),'Annotation'),'LegendInformation'),...
%         'IconDisplayStyle','off'); % Exclude line from legend
% end
phenoHandles = [];
for i=1:length(phenoScratch.phenoLegendSet)
    if 0==phenoScratch.phenoLegendSet(i),continue,end
    if 1==i
        color = [0 0 0];
        sym='o';
    else
        color = phenoScratch.phenoColors(i,:);
        sym='s';        
    end
        
    hPheno=plot(-5,-5,sym,'MarkerFaceColor',color,'MarkerEdgeColor','w',...
        'MarkerSize',12);
    phenoHandles = [phenoHandles hPheno];
    set(hPheno,'DisplayName',CellPhenotypes.descriptions{i});
end

hold off

if(~isempty(phenoHandles))
    legend(phenoHandles);
end

%let the user know that the drawing is done
set(Figures.tree.handle,'Pointer','arrow');
set(Figures.cells.handle,'Pointer','arrow');
end

function [xMin xCenter xMax phenoScratch] = traverseTree(trackID,initXmin,phenoScratch)
global CellTracks
if(~isempty(CellTracks(trackID).childrenTracks))
    [child1Xmin child1Xcenter child1Xmax phenoScratch] = traverseTree(CellTracks(trackID).childrenTracks(1),initXmin,phenoScratch);
    [child2Xmin child2Xcenter child2Xmax phenoScratch] = traverseTree(CellTracks(trackID).childrenTracks(2),child1Xmax+1,phenoScratch);
    xMin = min(child1Xmin,child2Xmin);
    xMax = max(child1Xmax,child2Xmax);
    if(child1Xcenter < child2Xcenter)
        drawHorizontalEdge(child1Xcenter,child2Xcenter,CellTracks(trackID).endTime+1,trackID);
        xCenter = (child2Xcenter-child1Xcenter)/2 + child1Xcenter;
    else
        drawHorizontalEdge(child2Xcenter,child1Xcenter,CellTracks(trackID).endTime+1,trackID);
        xCenter = (child1Xcenter-child2Xcenter)/2 + child2Xcenter;
    end
    phenoScratch = drawVerticalEdge(trackID,xCenter,phenoScratch);
else
    %This is when the edge is for a leaf node
    phenoScratch = drawVerticalEdge(trackID,initXmin,phenoScratch);
    xMin = initXmin;
    xCenter = initXmin;
    xMax = initXmin;
end
end

function drawHorizontalEdge(xMin,xMax,y,trackID)
global Figures
plot([xMin xMax],[y y],'-k','UserData',trackID);
%Place the line behind all other elements already graphed
h = get(gca,'child');
h = h([2:end, 1]);
set(gca, 'child', h);
end

function phenoScratch = drawVerticalEdge(trackID,xVal,phenoScratch)
global CellTracks Figures

%draw circle for node
FontSize = 8;
circleSize=8;

phenotype = GetTrackPhenotype(trackID);

yMin = CellTracks(trackID).startTime;
    %draw vertical line to represent edge length
    plot([xVal xVal],[yMin CellTracks(trackID).endTime+1],...
        '-k','UserData',trackID);

if ( phenotype > 1 ) 
    color = phenoScratch.phenoColors(phenotype,:);
    plot(xVal,yMin,'s',...
        'MarkerFaceColor',  color,...
        'MarkerEdgeColor',  'k',...
        'MarkerSize',       1.5*circleSize,...
        'UserData',         trackID);
    
    yPhenos = GetTrackPhenoypeTimes(trackID);
    if ( ~isempty(yPhenos) )
        plot(xVal*ones(size(yPhenos)),yPhenos,'rx','UserData',trackID);
    end
    
    phenoScratch.phenoLegendSet(phenotype)=1;

elseif(isempty(GetTimeOfDeath(trackID)))
    
     color = CellTracks(trackID).color;
    plot(xVal,yMin,'o',...
        'MarkerEdgeColor',  'k',...
        'MarkerFaceColor',  'w',...
        'MarkerSize',       circleSize,...
        'UserData',         trackID);
%     text(xVal,yMin,num2str(trackID),...
%         'HorizontalAlignment',  'center',...
%         'FontSize',             FontSize,...
%         'color',                color.text,...
%         'UserData',             trackID,...
%         'uicontextmenu',        Figures.tree.contextMenuHandle);
else
    yPhenos = GetTrackPhenoypeTimes(trackID);
    
    plot([xVal xVal],[yMin yPhenos(end)],...
        '-k','UserData',trackID);
    plot([xVal xVal],[yPhenos(end) CellTracks(trackID).endTime+1],...
        '--k','UserData',trackID);
    
    plot(xVal*ones(size(yPhenos)),yPhenos,'rx','UserData',trackID);
    
    plot(xVal,yMin,'o',...
        'MarkerFaceColor',  'k',...
        'MarkerEdgeColor',  'r',...
        'MarkerSize',       circleSize,...
        'UserData',         trackID);
%     text(xVal,yMin,num2str(trackID),...
%         'HorizontalAlignment',  'center',...
%         'FontSize',             FontSize,...
%         'color',                'r',...
%         'UserData',             trackID,...
%         'uicontextmenu',        Figures.tree.contextMenuHandle);
    phenoScratch.phenoLegendSet(1)=1;
end
end

