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

function DrawTree(familyID, endTime)

global CellFamilies CellTracks HashedCells Figures CellPhenotypes ResegState FluorData HaveFluor

if ( ~exist('endTime','var') )
    endTime = length(HashedCells);
end

if ( ~exist('familyID','var') || isempty(familyID) )
    Families.FindLargestTree();
    return;
end

if ( familyID > length(CellFamilies) )
    Families.FindLargestTree();
    return;
end

if(isempty(CellFamilies(familyID).tracks)),return,end

%let the user know that this might take a while
set(Figures.tree.handle,'Pointer','watch');
set(Figures.cells.handle,'Pointer','watch');

if ( ~isfield(Figures.tree,'axesHandle') || isempty(Figures.tree.axesHandle) )
    Figures.tree.axesHandle = axes('Parent', Figures.tree.handle);
    
    set(Figures.tree.axesHandle,...
        'YDir',     'reverse',...
        'YLim',     [-25 endTime],...
        'Position', [.06 .06 .90 .90],...
        'XColor',   'w',...
        'XTick',    [],...
        'Box',      'off',...
        'DrawMode', 'fast');
end

if ( ~UI.DrawPool.HasPool(Figures.tree.axesHandle) )
    numTracks = length(CellFamilies(familyID).tracks);
    
    hold(Figures.tree.axesHandle, 'on');
    
    hLine = line([0 1], [0 0], 'Parent',Figures.tree.axesHandle);
    UI.DrawPool.AddPool(Figures.tree.axesHandle, 'VertLines', hLine, 2*numTracks);
    UI.DrawPool.AddPool(Figures.tree.axesHandle, 'HorzLines', hLine, numTracks);
    delete(hLine);
    
    hMarker = plot(Figures.tree.axesHandle, 0,0, 'ro');
    UI.DrawPool.AddPool(Figures.tree.axesHandle, 'Markers', hMarker, 2*numTracks);
    delete(hMarker);
    
    hLabel = text(0,0, '', 'Parent',Figures.tree.axesHandle);
    UI.DrawPool.AddPool(Figures.tree.axesHandle, 'Labels', hLabel, numTracks);
    delete(hLabel);
    
    hold(Figures.tree.axesHandle, 'off');
end

Figures.tree.familyID = familyID;

rootTrackID = CellFamilies(familyID).rootTrackID;

figure(Figures.tree.handle);

% ylabel('Time (Frames)');

% title(overAxes, CONSTANTS.datasetName, 'Position',[0 0 1], 'HorizontalAlignment','left', 'Interpreter','none');

hold(Figures.tree.axesHandle, 'on');

% build a map with the heights for each node in the tree rooted at trackID
trackHeights = containers.Map('KeyType', 'uint32', 'ValueType', 'uint32');
computeTrackHeights(rootTrackID, trackHeights);

[xTracks bFamHasPheno] = simpleTraverseTree(rootTrackID, 0, trackHeights);

xMin = min(xTracks(:,2));
xMax = max(xTracks(:,2));

UI.DrawPool.StartDraw(Figures.tree.axesHandle);

% Clear non-pooled draw resources
cla(Figures.tree.axesHandle)

for i=1:size(xTracks,1)
    curTrack = xTracks(i,1);
    if ( ~isempty(CellTracks(curTrack).childrenTracks) )
        childLoc = getTrackLocation(CellTracks(curTrack).childrenTracks, xTracks);
        drawHorizontalEdge(childLoc(1), childLoc(2), CellTracks(curTrack).endTime+1, curTrack);
    end
end

for i=1:size(xTracks,1)
    drawVerticalEdge(xTracks(i,1), xTracks(i,2));
end

% if ( Figures.cells.showInterior )
%     debugDrawGraphEdits(familyID, xTracks);
% end

showResegStatus = get(Figures.cells.menuHandles.resegStatusMenu, 'Checked');
if ( strcmpi(showResegStatus, 'on') )
    minSpacing = abs(min(diff(xTracks(:,2))));
    if ( isempty(minSpacing) )
        minSpacing = 1;
    end

    pdelta = pixelDelta(Figures.tree.axesHandle);
    padLeft = min(minSpacing/3, 10*pdelta);
    for i=1:size(xTracks,1)
        drawResegInfo(xTracks(i,1), xTracks(i,2)-padLeft);
    end
end

UI.DrawPool.FinishDraw(Figures.tree.axesHandle);

set(Figures.tree.axesHandle, 'XLim', [xMin-1 xMax+1], 'YLim',[-25 endTime]);
% Figures.tree.axesHandle = overAxes;

if ( CellFamilies(familyID).bLocked )
    set(Figures.tree.menuHandles.lockMenu, 'Checked','on');
    set(Figures.cells.menuHandles.lockMenu, 'Checked','on');
    set(Figures.tree.axesHandle, 'Color',[.75 .75 .75]);
else
    set(Figures.tree.menuHandles.lockMenu, 'Checked','off');
    set(Figures.cells.menuHandles.lockMenu, 'Checked','off');
    set(Figures.tree.axesHandle, 'Color','w');
end

UI.UpdateTimeIndicatorLine();

zoom(Figures.tree.handle, 'reset');

phenoHandles = [];
hasPhenos = find(bFamHasPheno);
for i=1:length(hasPhenos)
    if ( hasPhenos(i) == 1 )
        color = [0 0 0];
        sym = 'o';
    else
        color = CellPhenotypes.colors(hasPhenos(i),:);
        sym = 's';
    end
    
    hPheno = plot(-5,-5,sym,'MarkerFaceColor',color,'MarkerEdgeColor','w',...
        'MarkerSize',12);
    
    phenoHandles = [phenoHandles hPheno];
    
    set(hPheno,'DisplayName',CellPhenotypes.descriptions{hasPhenos(i)});
end

% draw ticks to indicate which times have fluorescence
fluorTimes = find(HaveFluor);
pdelta = pixelDelta(Figures.tree.axesHandle);
x_lim = xlim;
% xlim = get(Figures.tree.axesHandle,'XLim');
% tickLen = (xlim(2) - xlim(1)) * 0.01;
for i=1:length(fluorTimes)
%    line([xlim(2)-tickLen xlim(2)], [fluorTimes(i) fluorTimes(i)],...
    line([x_lim(2)-10*pdelta x_lim(2)], [fluorTimes(i) fluorTimes(i)],...
    'color', 'green',...
    'linewidth', 1);
end

% Draw the "edit" line, and current resegable cirlces,if reseg is running
if ( ~isempty(ResegState) )
    treeXlims = get(Figures.tree.axesHandle,'XLim');
    resegTime = max(ResegState.currentTime-1,1);

    plot(Figures.tree.axesHandle, [treeXlims(1), treeXlims(2)],[resegTime, resegTime], '-b');

    viewLims = [xlim(Figures.cells.axesHandle); ylim(Figures.cells.axesHandle)];

    xStarts = [CellTracks(xTracks(:,1)).startTime];
    xEnds = [CellTracks(xTracks(:,1)).endTime];

    inXTracks = xTracks(((xStarts <= resegTime) & (xEnds >= resegTime)),:);

    [bIgnored bLong] = Segmentation.ResegFromTree.CheckIgnoreTracks(resegTime, inXTracks(:,1), viewLims);
    xResegLoc = inXTracks(~(bIgnored|bLong),2);
    
    indicatorList = [];
    for i=1:length(xResegLoc)
        indicatorList = [indicatorList plot(xResegLoc(i),resegTime, '.b', 'MarkerSize',12)];
    end

    Figures.tree.resegIndicators = indicatorList;
    
    UI.UpdateResegIndicators();
end

for i=1:size(xTracks,1)
    drawFluorMarkers(xTracks(i,1), xTracks(i,2), 4*pdelta);
end

hold(Figures.tree.axesHandle, 'off');

if(isempty(phenoHandles))
    legend(Figures.tree.axesHandle,'hide');
else
    legend(Figures.tree.axesHandle, phenoHandles, 'Location','NorthWest');
end

%let the user know that the drawing is done
set(Figures.tree.handle,'Pointer','arrow');
set(Figures.cells.handle,'Pointer','arrow');
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

function drawResegInfo(trackID, xVal)
    global Figures CellTracks CellHulls ResegLinks
    
    hulls = CellTracks(trackID).hulls;
    nzHulls = hulls(hulls ~= 0);
    
    bHasResegLink = any((ResegLinks(:,nzHulls) ~= 0),1);
    if ( nnz(bHasResegLink) == 0 )
        return;
    end
    
    [linkHulls,nextIdx] = find(ResegLinks(:,nzHulls(bHasResegLink)) ~= 0);
    nextHulls = nzHulls(bHasResegLink);
    
    nextTimes = [CellHulls(nextHulls).time];
    linkTimes = [CellHulls(linkHulls).time];
    
    for i=1:length(nextTimes)
        plot(Figures.tree.axesHandle, [xVal xVal], [nextTimes(i) linkTimes(i)], '-r');
    end
end

function hLine = drawHorizontalEdge(xMin,xMax,y,trackID)
    global Figures
%     plot([xMin xMax],[y y],'-k','UserData',trackID,'uicontextmenu',Figures.tree.contextMenuHandle);
    hLine = UI.DrawPool.GetHandle(Figures.tree.axesHandle, 'HorzLines');
    set(hLine, 'XData',[xMin xMax], 'YData',[y y],...
               'Color','k', 'UserData',trackID,...
               'uicontextmenu',Figures.tree.contextMenuHandle);
end

function drawVerticalEdge(trackID, xVal)
    global CellTracks CellPhenotypes Figures

    bDrawLabels = strcmp('on',get(Figures.tree.menuHandles.treeColorMenu, 'Checked'));
    bStructOnly = strcmp('on',get(Figures.tree.menuHandles.structOnlyMenu, 'Checked'));

    %draw circle for node
    [fontSize circleSize] = UI.GetFontShapeSizes(length(num2str(trackID)));

    if ~bDrawLabels
        fontSize=6;
    end
    yMin = CellTracks(trackID).startTime;

    phenotype = Tracks.GetTrackPhenotype(trackID);

    if ( phenotype ~= 1 )
        %draw vertical line to represent edge length
    %     plot([xVal xVal],[yMin CellTracks(trackID).endTime+1],...
    %         '-k','UserData',trackID,'uicontextmenu',Figures.tree.contextMenuHandle);

        hLine = UI.DrawPool.GetHandle(Figures.tree.axesHandle, 'VertLines');
        set(hLine, 'XData',[xVal xVal],...
                   'YData',[yMin CellTracks(trackID).endTime+1],...
                   'Color','k', 'UserData',trackID,...
                   'LineStyle','-',...
                   'uicontextmenu',Figures.tree.contextMenuHandle);

    else
        yPhenos = Tracks.GetTrackPhenoypeTimes(trackID);

%         plot([xVal xVal],[yMin yPhenos(end)],...
%             '-k','UserData',trackID);
%         plot([xVal xVal],[yPhenos(end) CellTracks(trackID).endTime+1],...
%             '--k','UserData',trackID,'uicontextmenu',Figures.tree.contextMenuHandle);
        hLine = UI.DrawPool.GetHandle(Figures.tree.axesHandle, 'VertLines');
        set(hLine, 'XData',[xVal xVal],...
                   'YData',[yMin yPhenos(end)],...
                   'Color','k', 'UserData',trackID,...
                   'LineStyle','-',...
                   'uicontextmenu',Figures.tree.contextMenuHandle);
        
        hLine = UI.DrawPool.GetHandle(Figures.tree.axesHandle, 'VertLines');
        set(hLine, 'XData',[xVal xVal],...
                   'YData',[yPhenos(end) CellTracks(trackID).endTime+1],...
                   'Color','k', 'UserData',trackID,...
                   'LineStyle','--',...
                   'uicontextmenu',Figures.tree.contextMenuHandle);
    end
    
    if ( bStructOnly )
        return;
    end
    
    drawTrackLabel(xVal, trackID, phenotype, bDrawLabels);
end

function drawTrackLabel(x, trackID, phenotype, bDrawLabels)
    global Figures CellTracks CellPhenotypes
    
    yMin = CellTracks(trackID).startTime;
    
    [fontSize circleSize] = UI.GetFontShapeSizes(length(num2str(trackID)));
    if ( ~bDrawLabels )
        fontSize = 6;
        phenoScale = 1.2;
    else
        phenoScale = 1.5;
    end
    
    textColor = getTextColor(trackID, phenotype, bDrawLabels);
    % Draw text
%     text(xVal,yMin,num2str(trackID),...
%         'HorizontalAlignment',  'center',...
%         'FontSize',             fontSize,...
%         'color',                TextColor,...
%         'UserData',             trackID,...
%         'uicontextmenu',        Figures.tree.contextMenuHandle);
    hLabel = UI.DrawPool.GetHandle(Figures.tree.axesHandle, 'Labels');
    set(hLabel, 'String',num2str(trackID),...
                'Position',[x, yMin],...
                'HorizontalAlignment','center',...
                'FontSize',fontSize,...
                'color',textColor,...
                'UserData',trackID,...
                'uicontextmenu',Figures.tree.contextMenuHandle);
    
    % Draw a dead cell marker
    if ( phenotype == 1 )
        hMarker = UI.DrawPool.GetHandle(Figures.tree.axesHandle, 'Markers');
        set(hMarker, 'XData',x, 'YData',yMin,...
                     'Marker','o',...
                     'MarkerFaceColor','k',...
                     'MarkerEdgeColor','r',...
                     'MarkerSize',circleSize,...
                     'UserData',trackID,...
                     'uicontextmenu',Figures.tree.contextMenuHandle);
        
        UI.DrawPool.SetDrawOrder(Figures.tree.axesHandle, [hMarker hLabel]);
        return;
    end
    
    % Draw a phenotype box
    hPheno = [];
    if ( phenotype > 1 )
        phenoColor = CellPhenotypes.colors(phenotype,:);
        hPheno = UI.DrawPool.GetHandle(Figures.tree.axesHandle, 'Markers');
        set(hPheno, 'XData',x, 'YData',yMin,...
                     'Marker','s',...
                     'MarkerFaceColor',phenoColor,...
                     'MarkerEdgeColor','w',...
                     'MarkerSize',phenoScale*circleSize,...
                     'UserData',trackID,...
                     'uicontextmenu',Figures.tree.contextMenuHandle);
    end
    
    if ( bDrawLabels )
        hMarker = UI.DrawPool.GetHandle(Figures.tree.axesHandle, 'Markers');
        set(hMarker, 'XData',x, 'YData',yMin,...
                     'Marker','o',...
                     'MarkerFaceColor',CellTracks(trackID).color.background,...
                     'MarkerEdgeColor',CellTracks(trackID).color.background,...
                     'MarkerSize',circleSize,...
                     'UserData',trackID,...
                     'uicontextmenu',Figures.tree.contextMenuHandle);
        
        
        UI.DrawPool.SetDrawOrder(Figures.tree.axesHandle, [hPheno hMarker hLabel]);
        return;
    end
    
    hMarker = [];
    if ( phenotype == 0 )
        hMarker = UI.DrawPool.GetHandle(Figures.tree.axesHandle, 'Markers');
        set(hMarker, 'XData',x, 'YData',yMin,...
                     'Marker','o',...
                     'MarkerFaceColor','w',...
                     'MarkerEdgeColor','k',...
                     'MarkerSize',circleSize,...
                     'UserData',trackID,...
                     'uicontextmenu',Figures.tree.contextMenuHandle);
    end
    
    UI.DrawPool.SetDrawOrder(Figures.tree.axesHandle, [hPheno hMarker hLabel]);
end

function textColor = getTextColor(trackID, phenotype, bDrawLabels)
    global CellTracks CellPhenotypes
    
    % Colors for dead cells
    if ( phenotype == 1 )
        textColor = 'r';
        return;
    end
    
    % Colors if track label colors are on
    if ( bDrawLabels )
        textColor = CellTracks(trackID).color.text;
        return;
    end
    
    textColor = 'k';
    % If not drawing labels, but the track has a phenotype
    if ( phenotype > 1 )
        phenoColor = CellPhenotypes.colors(phenotype,:);
        if ( ~isempty(phenoColor) )
            m = rgb2hsv(phenoColor);
            if ( m(1) > 0.5 )
                textColor = 'w';
            end
        end
        return;
    end
end

function [xTracks bFamHasPheno] = simpleTraverseTree(trackID, xVal, trackHeights)
    global CellTracks CellPhenotypes
    
    bFamHasPheno = false(length(CellPhenotypes.descriptions),1);
    phenoType = Tracks.GetTrackPhenotype(trackID);
    if ( phenoType > 0 )
        bFamHasPheno(phenoType) = 1;
    end
    
    if ( isempty(CellTracks(trackID).childrenTracks) )
        xTracks = [trackID xVal (xVal-0.5) (xVal+0.5) CellTracks(trackID).startTime CellTracks(trackID).endTime+1];
        return;
    end
    
    leftChild = 1;
    rightChild = 2;
    
    ID1 = CellTracks(trackID).childrenTracks(1);
    ID2 = CellTracks(trackID).childrenTracks(2);
    if ( trackHeights(ID1) < trackHeights(ID2) )
        leftChild = 2;
        rightChild = 1;
    end
    
    [xTracks bLeftChildHasPheno] = simpleTraverseTree(CellTracks(trackID).childrenTracks(leftChild), xVal, trackHeights);
    leftMax = max(xTracks(:,2));
    
    [xChild bRightChildHasPheno] = simpleTraverseTree(CellTracks(trackID).childrenTracks(rightChild), leftMax+1, trackHeights);
    xTracks = [xTracks;xChild];
    
    bFamHasPheno = (bFamHasPheno | bLeftChildHasPheno | bRightChildHasPheno);
    
    xCenter = mean(getTrackLocation(CellTracks(trackID).childrenTracks, xTracks));
    xTracks = [xTracks; trackID xCenter min(xTracks(:,3)) max(xTracks(:,4)) CellTracks(trackID).startTime max(xTracks(:,6))];
end

function xLoc = getTrackLocation(trackID, xTracks)
    xLoc = NaN*ones(1,length(trackID));
    for i=1:length(trackID)
        if ( any(xTracks(:,1) == trackID(i)) )
            xLoc(i) = xTracks(xTracks(:,1) == trackID(i), 2);
        end
    end
end

% Draws User edge edits for debugging
function debugDrawGraphEdits(familyID, xTracks)
    global CellFamilies CellTracks CellHulls HashedCells GraphEdits
    
    famHulls = [];
    xMin = min(xTracks(1,:));
    xMax = max(xTracks(1,:));
    
    for i=1:length(CellFamilies(familyID).tracks)
        curTrack = CellFamilies(familyID).tracks(i);
        famHulls = [famHulls CellTracks(curTrack).hulls(CellTracks(curTrack).hulls > 0)];
    end

    [rEdits cEdits] = find(GraphEdits);
    bKeep = (ismember(rEdits,famHulls) | ismember(cEdits,famHulls));
    rEdits = rEdits(bKeep);
    cEdits = cEdits(bKeep);
    
    randmap = hsv(128);
    randcols = randmap(randi(128,length(rEdits)),:);
    
    fromTimes = [CellHulls(rEdits).time];
    toTimes = [CellHulls(cEdits).time];
    for i=1:length(rEdits)
        xFromTrack = getTrackLocation(Hulls.GetTrackID(rEdits(i)), xTracks);
        xToTrack = getTrackLocation(Hulls.GetTrackID(cEdits(i)), xTracks);
        
        plotStyle = '-';
        if ( isnan(xFromTrack) )
            xFromTrack = xMin-1;
            if ( xToTrack > (xMax-xMin)/2 )
                xFromTrack = xMax+1;
            end
            plotStyle = '--';
        elseif ( isnan(xToTrack) )
            xToTrack = xMin-1;
            if ( xFromTrack > (xMax-xMin)/2 )
                xToTrack = xMax+1;
            end
            plotStyle = '--';
        end
        
        if ( GraphEdits(rEdits(i),cEdits(i)) < 0 )
            plotStyle = 'x';
            plot([xFromTrack xToTrack], [fromTimes(i) toTimes(i)], plotStyle);
            continue;
        end
        
        editTime = abs(toTimes(i)-fromTimes(i)) / 80;
        yrat = ((xMax-xMin+2) / (length(HashedCells) + 1));
        drawSnakey([xFromTrack xToTrack], [fromTimes(i) toTimes(i)], (20*yrat)*editTime*[1 1], (20*yrat)*editTime*[1 1]/yrat, plotStyle, randcols(i,:), 1);
    end
end

% Draws a an interpolated curve around the standard tree-edge
function drawSnakey(x,y, a,b, style, color, width)
    t=0:0.01:1;
    xint = (2*(x(1)-x(2)) + (a(1)+a(2)))*(t.^3) + (3*(x(2)-x(1)) - (a(2)+2*a(1)))*(t.^2) + a(1)*t + x(1);
    yint = (2*(y(1)-y(2)) + (b(1)+b(2)))*(t.^3) + (3*(y(2)-y(1)) - (b(2)+2*b(1)))*(t.^2) + b(1)*t + y(1);
    
    plot(xint, yint, style, 'LineWidth',width, 'Color',color);
end

function drawFluorMarkers(trackID, xVal, delta)
global CellTracks;

if (~isfield(CellTracks, 'markerTimes'))
    return;
end

ct = CellTracks(trackID);
len = size(ct.markerTimes, 2);

if (len == 0)
    return;
end

% if fluor on in first frame, draw marker from startTime to first frame
if (ct.markerTimes(1,1) > ct.startTime)
    if (ct.markerTimes(2,1) > 0)
        drawVertFluor(trackID, xVal, ct.startTime, ct.markerTimes(1,1), delta);
        state = 1;
    else
        state = 0;
    end
else
    state = -1;
end

% if fluor is on for a frame, draw marker until next fluor frame
for i=1:len - 1
    if (ct.markerTimes(2,i) > 0)
        drawVertFluor(trackID, xVal, ct.markerTimes(1,i), ct.markerTimes(1,i+1), delta);
        if (state == 0)
            drawHorzFluor(trackID, xVal, ct.markerTimes(1, i), 'g');
        end
        state = 1;
    elseif (state == 1)
        drawHorzFluor(trackID, xVal, ct.markerTimes(1, i), 'k');
        state = 0;
    end
end

% if fluor is on for last frame, draw marker until endTime
if (ct.markerTimes(1, len) < ct.endTime)
    if (ct.markerTimes(2,len) > 0)
        drawVertFluor(trackID, xVal, ct.markerTimes(1, len), ct.endTime, delta);
        if (state == 0)
            drawHorzFluor(trackID, xVal, ct.markerTimes(1, len), 'g');
        end
    elseif (state == 1)
        drawHorzFluor(trackID, xVal, ct.markerTimes(1, len), 'k');
    end
end

end

% how far is 1 pixel in normalized units?
function delta = pixelDelta(axHandle)

x_lim = xlim(axHandle);
set(axHandle, 'units', 'pixels');
pos = get(axHandle, 'position');
delta = x_lim(2) / pos(3);
set(axHandle, 'units', 'normalized');

end

function drawVertFluor(trackID, x, yMin, yMax, delta)
global Figures;

plot([x+delta x+delta], [yMin yMax],...
    '-g','LineWidth',1,...
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
