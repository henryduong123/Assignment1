% DrawTree.m - This will draw the family tree of the given family.

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

function DrawTree(familyID)

global CellFamilies HashedCells Figures CellPhenotypes FluorData HaveFluor

if ( ~exist('familyID','var') || isempty(familyID) )
    Families.FindLargestTree();
    return;
end

if ( familyID > length(CellFamilies) )
    Families.FindLargestTree();
    return;
end
   
phenoScratch.phenoColors = hsv(length(CellPhenotypes.descriptions));
phenoScratch.phenoLegendSet = zeros(length(CellPhenotypes.descriptions),1);

if(isempty(CellFamilies(familyID).tracks)),return,end

%let the user know that this might take a while
set(Figures.tree.handle,'Pointer','watch');
set(Figures.cells.handle,'Pointer','watch');

Figures.tree.familyID = familyID;

trackID = CellFamilies(familyID).tracks(1);

figure(Figures.tree.handle);
delete(gca);

overAxes = axes;
    
set(overAxes,...
    'YDir',     'reverse',...
    'YLim',     [-10 length(HashedCells)],...
    'Position', [.06 .06 .90 .90],...
    'XColor',   'w',...
    'XTick',    [],...
    'Box',      'off');
% ylabel('Time (Frames)');

% title(overAxes, CONSTANTS.datasetName, 'Position',[0 0 1], 'HorizontalAlignment','left', 'Interpreter','none');

hold on

% build a map with the heights for each node in the tree rooted at trackID
trackHeights = containers.Map('KeyType', 'uint32', 'ValueType', 'uint32');
computeTrackHeights(trackID, trackHeights);

[xMin xCenter xMax phenoScratch] = traverseTree(trackID,0,phenoScratch, trackHeights);

set(overAxes,...
    'XLim',     [xMin-1 xMax+1]);
Figures.tree.axesHandle = overAxes;

if ( CellFamilies(familyID).bLocked )
    set(Figures.tree.menuHandles.lockMenu, 'Checked','on');
    set(Figures.cells.menuHandles.lockMenu, 'Checked','on');
    set(overAxes, 'Color',[.75 .75 .75]);
else
    set(Figures.tree.menuHandles.lockMenu, 'Checked','off');
    set(Figures.cells.menuHandles.lockMenu, 'Checked','off');
    set(overAxes, 'Color','w');
end

UI.UpdateTimeIndicatorLine();
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

% draw ticks to indicate which times have fluorescence
fluorTimes = find(HaveFluor);
xlim = get(Figures.tree.axesHandle,'XLim');
tickLen = (xlim(2) - xlim(1)) * 0.01;
for i=1:length(fluorTimes)
    line([xlim(2)-tickLen xlim(2)], [fluorTimes(i) fluorTimes(i)],...
    'color', 'green',...
    'linewidth', 1);
end

hold off

if(~isempty(phenoHandles))
    legend(phenoHandles);
end

%let the user know that the drawing is done
set(Figures.tree.handle,'Pointer','arrow');
set(Figures.cells.handle,'Pointer','arrow');
end

function [xMin xCenter xMax phenoScratch labelHandles] = traverseTree(trackID,initXmin,phenoScratch, trackHeights)
global CellTracks

if(~isempty(CellTracks(trackID).childrenTracks))
    % the taller subtree should go on the left
    ID1 = CellTracks(trackID).childrenTracks(1);
    ID2 = CellTracks(trackID).childrenTracks(2);
    if (trackHeights(ID1) >= trackHeights(ID2))
        left = ID1;
        right = ID2;
    else
        left = ID2;
        right = ID1;
    end
    
    [child1Xmin child1Xcenter child1Xmax phenoScratch child1Handles] = traverseTree(left,initXmin,phenoScratch,trackHeights);
    [child2Xmin child2Xcenter child2Xmax phenoScratch child2Handles] = traverseTree(right,child1Xmax+1,phenoScratch,trackHeights);
    xMin = min(child1Xmin,child2Xmin);
    xMax = max(child1Xmax,child2Xmax);
    
    minChildCenter = min([child1Xcenter,child2Xcenter]);
    maxChildCenter = max([child1Xcenter,child2Xcenter]);
    
    hLine = drawHorizontalEdge(minChildCenter,maxChildCenter,CellTracks(trackID).endTime+1,trackID);
    xCenter = mean([child1Xcenter,child2Xcenter]);
        
    [phenoScratch labelHandles] = drawVerticalEdge(trackID,xCenter,phenoScratch);
	
%     diamondHandle = plot(xCenter,CellTracks(trackID).endTime+1,'d', ...
%             'MarkerFaceColor',  [.5 .5 .5],...
%             'MarkerEdgeColor',  [0 0 0],...
%             'MarkerSize',       15,...
%             'ButtonDownFcn',    @mitosisHandleDown);
%     mitosisHandles = struct('trackID', {trackID},...
%         'hLine', {hLine},...
%         'child1Handles', {child1Handles},...
%         'child2Handles', {child2Handles},...
%         'diamondHandle', {diamondHandle});
%     
%     set(diamondHandle, 'UserData', mitosisHandles);
else
    %This is when the edge is for a leaf node
    [phenoScratch labelHandles] = drawVerticalEdge(trackID,initXmin,phenoScratch);
    xMin = initXmin;
    xCenter = initXmin;
    xMax = initXmin;
end
end

% WCM - 10/1/2012 - Created
% This function does a breadth-first search starting from trackID and
% computes the height of each node in the tree. These are stored in the map
% trackHeights.
function height = computeTrackHeights(trackID, trackHeights)
global CellTracks
    if(~isempty(CellTracks(trackID).childrenTracks))
        % root node
        leftHeight = computeTrackHeights(CellTracks(trackID).childrenTracks(1), trackHeights);
        rightHeight = computeTrackHeights(CellTracks(trackID).childrenTracks(2), trackHeights);
        height = 1 + max(leftHeight, rightHeight);
    else
        % leaf node
        height = 1;
    end
    trackHeights(trackID) = height;
end

% NLS - 6/8/2012 - Created
function mitosisHandleDown(src,evt)
global Figures mitosisMotionListener mitosisMouseUpListener CellTracks
    mitosisHandle = get(src,'UserData');
    children = CellTracks(mitosisHandle.trackID).childrenTracks;
    Figures.tree.movingMitosis = children;
    mexDijkstra('initGraph', Tracker.GetCostMatrix());
    
    Figures.tree.dragging = src;
end

function hLine = drawHorizontalEdge(xMin,xMax,y,trackID)
global Figures
hLine = plot([xMin xMax],[y y],'-k','UserData',trackID,'uicontextmenu',Figures.tree.contextMenuHandle);
%Place the line behind all other elements already graphed
h = get(gca,'child');
h = h([2:end, 1]);
set(gca, 'child', h);
end

function [phenoScratch, labelHandles] = drawVerticalEdge(trackID,xVal,phenoScratch)
global CellTracks Figures

labelHandles = [];
bDrawLabels = strcmp('on',get(Figures.tree.menuHandles.labelsMenu, 'Checked'));

%draw circle for node
[FontSize circleSize] = UI.GetFontShapeSizes(length(num2str(trackID)));

if ~bDrawLabels
        FontSize=6;
end
yMin = CellTracks(trackID).startTime;

phenotype = Tracks.GetTrackPhenotype(trackID);

if ( phenotype ~= 1 )
    %draw vertical line to represent edge length
    plot([xVal xVal],[yMin CellTracks(trackID).endTime+1],...
        '-k','UserData',trackID,'uicontextmenu',Figures.tree.contextMenuHandle);
    bHasPheno = 0;
    if bDrawLabels
        FaceColor = CellTracks(trackID).color.background;
        EdgeColor = CellTracks(trackID).color.background;
        TextColor = CellTracks(trackID).color.text;
    else
        FaceColor = 'w';
        EdgeColor = 'k';

        cPheno = [];
        if (phenotype > 0)
            cPheno = phenoScratch.phenoColors(phenotype,:);
        end
        
        if isempty(cPheno)
            TextColor='k';
        else
            m=rgb2hsv(cPheno);
            if m(1)>0.5
                TextColor='w';
            else
                TextColor='k';
            end
        end
    end
    if ( phenotype > 1 )
        if bDrawLabels,scaleMarker=1.5;else,scaleMarker=1.2;end;
        color = phenoScratch.phenoColors(phenotype,:);
        labelHandles = [labelHandles plot(xVal,yMin,'s',...
            'MarkerFaceColor',  color,...
            'MarkerEdgeColor',  'w',...
            'MarkerSize',       scaleMarker*circleSize,...
            'UserData',         trackID,...
            'uicontextmenu',    Figures.tree.contextMenuHandle)];
        phenoScratch.phenoLegendSet(phenotype)=1;
        bHasPheno = 1;
    end
    
    yPhenos = Tracks.GetTrackPhenoypeTimes(trackID);
    if ( ~isempty(yPhenos) )
        plot(xVal*ones(size(yPhenos)),yPhenos,'rx','UserData',trackID);
    end
    
    if ~(bHasPheno && ~bDrawLabels)
        labelHandles = [labelHandles plot(xVal,yMin,'o',...
            'MarkerFaceColor',  FaceColor,...
            'MarkerEdgeColor',  EdgeColor,...
            'MarkerSize',       circleSize,...
            'UserData',         trackID,...
            'uicontextmenu',    Figures.tree.contextMenuHandle)];
    end
    labelHandles = [labelHandles text(xVal,yMin,num2str(trackID),...
        'HorizontalAlignment',  'center',...
        'FontSize',             FontSize,...
        'color',                TextColor,...
        'UserData',             trackID,...
        'uicontextmenu',        Figures.tree.contextMenuHandle)];
    
else
    yPhenos = Tracks.GetTrackPhenoypeTimes(trackID);
    
    plot([xVal xVal],[yMin yPhenos(end)],...
        '-k','UserData',trackID);
    plot([xVal xVal],[yPhenos(end) CellTracks(trackID).endTime+1],...
        '--k','UserData',trackID,'uicontextmenu',Figures.tree.contextMenuHandle);
    
	plot(xVal*ones(size(yPhenos)),yPhenos,'rx','UserData',trackID);
    
    labelHandles = [labelHandles plot(xVal,yMin,'o',...
        'MarkerFaceColor',  'k',...
        'MarkerEdgeColor',  'r',...
        'MarkerSize',       circleSize,...
        'UserData',         trackID,...
        'uicontextmenu',    Figures.tree.contextMenuHandle)];
    labelHandles = [labelHandles text(xVal,yMin,num2str(trackID),...
        'HorizontalAlignment',  'center',...
        'FontSize',             FontSize,...
        'color',                'r',...
        'UserData',             trackID,...
        'uicontextmenu',        Figures.tree.contextMenuHandle)];
    phenoScratch.phenoLegendSet(1)=1;
end

% if (trackID == 15844 || trackID == 18075)
%     trackID=trackID;
% end
% if (trackID == 17984)
%     trackID=17984;
% end
if (trackID == 18386)
    trackID = 18386;
end
% if (isfield(CellTracks(trackID),'markerTimes') && ~isempty(CellTracks(trackID).markerTimes))
%     if(CellTracks(trackID).markerTimes(2,1))
%         if (size(CellTracks(trackID).markerTimes, 2) == 1)
%             drawVertFluor(trackID, xVal, yMin, CellTracks(trackID).markerTimes(1,1));
%         else
%             drawVertFluor(trackID, xVal, yMin, CellTracks(trackID).markerTimes(1,2));
%         end            
%     end
%     for i=2:length(CellTracks(trackID).markerTimes)-1
%         if(CellTracks(trackID).markerTimes(2,i))
%             drawVertFluor(trackID, xVal, CellTracks(trackID).markerTimes(1,i), CellTracks(trackID).markerTimes(1,i+1)); 
%         end
%     end
%     if(CellTracks(trackID).markerTimes(2,end))
%         drawVertFluor(trackID, xVal, CellTracks(trackID).markerTimes(1,end), CellTracks(trackID).endTime+1); 
%     end
% end

if (isfield(CellTracks(trackID),'markerTimes') && ~isempty(CellTracks(trackID).markerTimes))
    yFrom = yMin;
    wasGreen = 0;
    drewLine = 0;
    for i=1:size(CellTracks(trackID).markerTimes, 2)
        if(CellTracks(trackID).markerTimes(2,i))
            drawVertFluor(trackID, xVal, yFrom, CellTracks(trackID).markerTimes(1,i));
            wasGreen = 1;
            drewLine = 0;
            if (~CellTracks(trackID).fluorTimes(2,i))
                drawHorzFluor(trackID, xVal, CellTracks(trackID).markerTimes(1,i), 'g');
            end
        elseif (wasGreen && ~drewLine)
%             drawVertLostFluor(trackID, xVal, yFrom, CellTracks(trackID).markerTimes(1,i));
            drawVertFluor(trackID, xVal, yFrom, CellTracks(trackID).markerTimes(1,i));
%            if (CellTracks(trackID).fluorTimes(2,i))
                drawHorzFluor(trackID, xVal, CellTracks(trackID).markerTimes(1,i), 'k');
%            end
            drewLine = 1;
        end
        yFrom = CellTracks(trackID).markerTimes(1,i);
    end
    if(CellTracks(trackID).markerTimes(2,end))
        drawVertFluor(trackID, xVal, CellTracks(trackID).markerTimes(1,end), CellTracks(trackID).endTime+1);
%     elseif (wasGreen)
%         drawVertLostFluor(trackID, xVal, CellTracks(trackID).markerTimes(1,end), CellTracks(trackID).endTime+1);
    end
end
    


end

function drawVertFluor(trackID, x, yMin, yMax)
global Figures;

plot([x x], [yMin yMax],...
    '-g','LineWidth',3,...
    'UserData',trackID,'uicontextmenu',Figures.tree.contextMenuHandle);
end

function drawVertLostFluor(trackID, x, yMin, yMax)
global Figures;

plot([x x], [yMin yMax],...
    '-r','LineWidth',3,...
    'UserData',trackID,'uicontextmenu',Figures.tree.contextMenuHandle);
plot([x x], [yMin yMax],...
    'xr','LineWidth',11,...
    'UserData',trackID,'uicontextmenu',Figures.tree.contextMenuHandle);
end

function drawHorzFluor(trackID, x, y, colorspec)
global Figures;

% xlim = get(Figures.tree.axesHandle,'XLim');
% tickLen = (xlim(2) - xlim(1)) * 0.01;
tickLen = 0.4;

%xlim = get(Figures.tree.axesHandle,'XLim');
%tickLen = (xlim(2) - xlim(1)) * 0.01;
%line([xlim(2)-tickLen xlim(2)], [fluorTimes(i) fluorTimes(i)],...

plot([x-tickLen x+tickLen], [y y],...
    ['-' colorspec],'LineWidth',1,...
    'UserData',trackID,'uicontextmenu',Figures.tree.contextMenuHandle);
end
