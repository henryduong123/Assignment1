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

global CellFamilies HashedCells Figures CellPhenotypes  

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
    'YLim',     [0 length(HashedCells)],...
    'Position', [.06 .06 .90 .90],...
    'XColor',   'w',...
    'XTick',    [],...
    'Box',      'off');
% ylabel('Time (Frames)');

% title(overAxes, CONSTANTS.datasetName, 'Position',[0 0 1], 'HorizontalAlignment','left', 'Interpreter','none');

hold on

[xMin xCenter xMax phenoScratch] = traverseTree(trackID,0,phenoScratch);

set(overAxes,...
    'XLim',     [xMin-1 xMax+1]);
Figures.tree.axesHandle = overAxes;
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

hold off

if(~isempty(phenoHandles))
    legend(phenoHandles);
end

%let the user know that the drawing is done
set(Figures.tree.handle,'Pointer','arrow');
set(Figures.cells.handle,'Pointer','arrow');
end

function [xMin xCenter xMax phenoScratch labelHandles] = traverseTree(trackID,initXmin,phenoScratch)
global CellTracks

if(~isempty(CellTracks(trackID).childrenTracks))
    [child1Xmin child1Xcenter child1Xmax phenoScratch child1Handles] = traverseTree(CellTracks(trackID).childrenTracks(1),initXmin,phenoScratch);
    [child2Xmin child2Xcenter child2Xmax phenoScratch child2Handles] = traverseTree(CellTracks(trackID).childrenTracks(2),child1Xmax+1,phenoScratch);
    xMin = min(child1Xmin,child2Xmin);
    xMax = max(child1Xmax,child2Xmax);
    
    minChildCenter = min([child1Xcenter,child2Xcenter]);
    maxChildCenter = max([child1Xcenter,child2Xcenter]);
    
    hLine = drawHorizontalEdge(minChildCenter,maxChildCenter,CellTracks(trackID).endTime+1,trackID);
    xCenter = mean([child1Xcenter,child2Xcenter]);
        
    [phenoScratch labelHandles] = drawVerticalEdge(trackID,xCenter,phenoScratch);
	
    diamondHandle = plot(xCenter,CellTracks(trackID).endTime+1,'d', ...
            'MarkerFaceColor',  [.5 .5 .5],...
            'MarkerEdgeColor',  [0 0 0],...
            'MarkerSize',       15,...
            'ButtonDownFcn',    @mitosisHandleDown);
    mitosisHandles = struct('trackID', {trackID},...
        'hLine', {hLine},...
        'child1Handles', {child1Handles},...
        'child2Handles', {child2Handles},...
        'diamondHandle', {diamondHandle});
    
    set(diamondHandle, 'UserData', mitosisHandles);
else
    %This is when the edge is for a leaf node
    [phenoScratch labelHandles] = drawVerticalEdge(trackID,initXmin,phenoScratch);
    xMin = initXmin;
    xCenter = initXmin;
    xMax = initXmin;
end
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
end


