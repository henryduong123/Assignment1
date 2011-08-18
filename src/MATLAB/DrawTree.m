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
%This will draw the family tree of the given family.


global CellFamilies HashedCells Figures CONSTANTS CellTracks CellPhenotypes  
   
phenoScratch.phenoColors = hsv(length(CellPhenotypes.contextMenuID));
phenoScratch.phenoLegendSet = zeros(length(CellPhenotypes.contextMenuID),1);

if(~isfield(CONSTANTS,'timeResolution'))
    CONSTANTS.timeResolution = 10;
end

if(isempty(CellFamilies(familyID).tracks)),return,end

%let the user know that this might take a while
set(Figures.tree.handle,'Pointer','watch');
set(Figures.cells.handle,'Pointer','watch');

Figures.tree.familyID = familyID;

trackID = CellFamilies(familyID).tracks(1);

figure(Figures.tree.handle);
delete(gca);
% delete(gca);
% hold off
% 
% underAxes = axes;
% 
% set(underAxes,...
%     'YDir',            'reverse',...
%     'YLim',             [0 length(HashedCells)],...
%     'Position',         [.07 .06 .80 .90],...
%     'YAxisLocation',    'right',...  
%     'YLim',             [0 length(HashedCells)*CONSTANTS.timeResolution/60],...
%     'XColor',           'w',...
%     'XTick',            [],...
%     'Box',              'off');
% ylabel('Time (Hours)');
% axis off

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
plot([xMin xMax],[y y],'-k','UserData',trackID,'uicontextmenu',Figures.tree.contextMenuHandle);
%Place the line behind all other elements already graphed
h = get(gca,'child');
h = h([2:end, 1]);
set(gca, 'child', h);
end

function phenoScratch = drawVerticalEdge(trackID,xVal,phenoScratch)
global CellTracks Figures

bDrawLabels = strcmp('on',get(Figures.tree.menuHandles.labelsMenu, 'Checked'));

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

if ~bDrawLabels
        FontSize=6;
end
yMin = CellTracks(trackID).startTime;

phenotype = GetTrackPhenotype(trackID);

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
        plot(xVal,yMin,'s',...
            'MarkerFaceColor',  color,...
            'MarkerEdgeColor',  'w',...
            'MarkerSize',       scaleMarker*circleSize,...
            'UserData',         trackID,...
            'uicontextmenu',    Figures.tree.contextMenuHandle);
        phenoScratch.phenoLegendSet(phenotype)=1;
        bHasPheno = 1;
    end
    
    yPhenos = GetTrackPhenoypeTimes(trackID);
    if ( ~isempty(yPhenos) )
        plot(xVal*ones(size(yPhenos)),yPhenos,'rx','UserData',trackID);
    end
    
    if ~(bHasPheno && ~bDrawLabels)
        plot(xVal,yMin,'o',...
            'MarkerFaceColor',  FaceColor,...
            'MarkerEdgeColor',  EdgeColor,...
            'MarkerSize',       circleSize,...
            'UserData',         trackID,...
            'uicontextmenu',    Figures.tree.contextMenuHandle);
    end
    text(xVal,yMin,num2str(trackID),...
        'HorizontalAlignment',  'center',...
        'FontSize',             FontSize,...
        'color',                TextColor,...
        'UserData',             trackID,...
        'uicontextmenu',        Figures.tree.contextMenuHandle);
    
else
    yPhenos = GetTrackPhenoypeTimes(trackID);
    
    plot([xVal xVal],[yMin yPhenos(end)],...
        '-k','UserData',trackID);
    plot([xVal xVal],[yPhenos(end) CellTracks(trackID).endTime+1],...
        '--k','UserData',trackID,'uicontextmenu',Figures.tree.contextMenuHandle);
    
	plot(xVal*ones(size(yPhenos)),yPhenos,'rx','UserData',trackID);
    
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
    phenoScratch.phenoLegendSet(1)=1;
end
end

