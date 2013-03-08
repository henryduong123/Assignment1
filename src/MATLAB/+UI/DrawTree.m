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

global CellFamilies CellTracks HashedCells Figures CellPhenotypes

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

Figures.tree.familyID = familyID;

trackID = CellFamilies(familyID).tracks(1);

figure(Figures.tree.handle);
delete(gca);

overAxes = axes;
    
set(overAxes,...
    'YDir',     'reverse',...
    'YLim',     [0 length(HashedCells)],...
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

phenoColors = hsv(length(CellPhenotypes.descriptions));
phenoLength = length(CellPhenotypes.descriptions);
[xTracks bFamHasPheno] = simpleTraverseTree(trackID, 0, phenoLength, trackHeights);

xMin = min(xTracks(:,2));
xMax = max(xTracks(:,2));

for i=1:size(xTracks,1)
    curTrack = xTracks(i,1);
    if ( ~isempty(CellTracks(curTrack).childrenTracks) )
        childLoc = getTrackLocation(CellTracks(curTrack).childrenTracks, xTracks);
        drawHorizontalEdge(childLoc(1), childLoc(2), CellTracks(curTrack).endTime+1, curTrack);
    end
end

for i=1:size(xTracks,1)
    drawVerticalEdge(xTracks(i,1), xTracks(i,2), phenoColors);
end

if ( Figures.cells.showInterior )
    debugDrawGraphEdits(familyID, xTracks);
end

set(overAxes, 'XLim', [xMin-1 xMax+1]);
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
hasPhenos = find(bFamHasPheno);
for i=1:length(hasPhenos)
    if ( hasPhenos(i) == 1 )
        color = [0 0 0];
        sym = 'o';
    else
        color = phenoColors(hasPhenos(i),:);
        sym = 's';
    end
    
    hPheno = plot(-5,-5,sym,'MarkerFaceColor',color,'MarkerEdgeColor','w',...
        'MarkerSize',12);
    
    phenoHandles = [phenoHandles hPheno];
    
    set(hPheno,'DisplayName',CellPhenotypes.descriptions{hasPhenos(i)});
end

hold off

if(~isempty(phenoHandles))
    legend(phenoHandles);
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

function hLine = drawHorizontalEdge(xMin,xMax,y,trackID)
    global Figures
    plot([xMin xMax],[y y],'-k','UserData',trackID,'uicontextmenu',Figures.tree.contextMenuHandle);
end

function labelHandles = drawVerticalEdge(trackID, xVal, phenoColors)
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
            cPheno = phenoColors(phenotype,:);
        end
        
        if isempty(cPheno)
            TextColor='k';
        else
            m = rgb2hsv(cPheno);
            if m(1)>0.5
                TextColor='w';
            else
                TextColor='k';
            end
        end
    end
    if ( phenotype > 1 )
        if bDrawLabels
            scaleMarker=1.5;
        else
            scaleMarker=1.2;
        end;
        
        color = phenoColors(phenotype,:);
        labelHandles = [labelHandles plot(xVal,yMin,'s',...
            'MarkerFaceColor',  color,...
            'MarkerEdgeColor',  'w',...
            'MarkerSize',       scaleMarker*circleSize,...
            'UserData',         trackID,...
            'uicontextmenu',    Figures.tree.contextMenuHandle)];
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
end
end

function [xTracks bFamHasPheno] = simpleTraverseTree(trackID, xVal, phenoLength, trackHeights)
    global CellTracks
    
    bFamHasPheno = false(phenoLength,1);
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
    
    [xTracks bLeftChildHasPheno] = simpleTraverseTree(CellTracks(trackID).childrenTracks(leftChild), xVal, phenoLength, trackHeights);
    leftMax = max(xTracks(:,2));
    
    [xChild bRightChildHasPheno] = simpleTraverseTree(CellTracks(trackID).childrenTracks(rightChild), leftMax+1, phenoLength, trackHeights);
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

