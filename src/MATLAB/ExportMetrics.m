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

function ExportMetrics(src,evnt)

global CellTracks CONSTANTS

trackMetrics = [];

for i=1:length(CellTracks)
    trackMetrics = [trackMetrics getMetrics(i,CellTracks(i))];
end

data = 'Cell Label,Number of Frames,First Frame,Last Frame,Origin Cell,Parent,Child 1,Child 2,Phenotype,Dies on Frame,Mean Speed,Standard Deviation Speed,Min Speed,Max Speed,Mean Area,Standard Deviation Area,Min Area,Max Area,Mean Pixel,Standard Deviation Pixel\n';
for i=1:length(trackMetrics)
    data = [data num2str(trackMetrics(i).trackID) ',' num2str(trackMetrics(i).timeFrame) ',' num2str(trackMetrics(i).firstFrame) ',' num2str(trackMetrics(i).lastFrame) ',' num2str(trackMetrics(i).familyID) ',' ];
    if(~isempty(trackMetrics(i).parent))
        data = [data num2str(trackMetrics(i).parent) ','];
    else
        data = [data ','];
    end
    if(~isempty(trackMetrics(i).children))
        data = [data num2str(trackMetrics(i).children(1)) ','];
        if(length(trackMetrics(i).children)>=2)
            data = [data num2str(trackMetrics(i).children(2)) ','];
        else
            data = [data ','];
        end
    else
        data = [data ',,'];
    end
    data = [data trackMetrics(i).phenotype ','];
    if(~isempty(trackMetrics(i).death))
        data = [data num2str(trackMetrics(i).death) ','];
    else
        data = [data ','];
    end
    data = [data num2str(trackMetrics(i).meanSpeed) ',' num2str(trackMetrics(i).standardDeviationSpeed) ','...
        num2str(trackMetrics(i).minSpeed) ',' num2str(trackMetrics(i).maxSpeed) ','...
        num2str(trackMetrics(i).meanArea) ',' num2str(trackMetrics(i).standardDeviationArea) ','...
        num2str(trackMetrics(i).minArea) ',' num2str(trackMetrics(i).maxArea) ','...
        num2str(trackMetrics(i).meanIntesity) ',' num2str(trackMetrics(i).standardDeviationIntesity) '\n'];
end

load('LEVerSettings.mat');
file = fopen([settings.matFilePath CONSTANTS.datasetName '_metrics.csv'],'w');
if(file==-1)
    warndlg(['The file ' settings.matFilePath CONSTANTS.datasetName '_metrics.csv might be opened.  Please close and try again.']);
    return
end
fprintf(file,data);
fclose(file);
msgbox(['Metrics have been saved to: ' settings.matFilePath CONSTANTS.datasetName '_metrics.csv'],'Saved','help');
end

function trackMetric = getMetrics(trackID,track)
global CellHulls CellPhenotypes

trackMetric = [];
if(length(track.hulls)<3),return,end

trackMetric.trackID = trackID;
trackMetric.timeFrame = length(track.hulls);
trackMetric.firstFrame = track.startTime;
trackMetric.lastFrame = track.endTime;
trackMetric.parent = track.parentTrack;
trackMetric.children = track.childrenTracks;
pheno = GetTrackPhenotype(trackID);
if( pheno > 0 )
    trackMetric.phenotype = CellPhenotypes.descriptions{pheno};
else
    trackMetric.phenotype = '';
end
trackMetric.death = GetTimeOfDeath(trackID);
trackMetric.familyID = track.familyID;

velosities = [];
areas = [];
intensities = [];

for i=1:length(track.hulls)-1
    if(~track.hulls(i)),continue,end
    j = i+1;
    if(~track.hulls(j)) %find the next frame where a hull exits
        for k=j:length(track.hulls)
            if(track.hulls(k)),break,end
        end
        if(~track.hulls(k)),break,end %reached the end
        j = k;
    end
    dist = sqrt((CellHulls(track.hulls(j)).centerOfMass(1)-CellHulls(track.hulls(i)).centerOfMass(1))^2 + ...
        (CellHulls(track.hulls(j)).centerOfMass(2)-CellHulls(track.hulls(i)).centerOfMass(2))^2);
    v = dist/(j-i);
    velosities = [velosities v];
    areas = [areas length(CellHulls(track.hulls(i)).indexPixels)];
    intensities = [intensities CellHulls(track.hulls(i)).imagePixels'];
end
if(track.hulls(length(track.hulls)))
    areas = [areas length(CellHulls(track.hulls(length(track.hulls))).indexPixels)];%i only goes to length -1;
end
trackMetric.meanSpeed = mean(velosities);
trackMetric.minSpeed = min(velosities);
trackMetric.maxSpeed = max(velosities);
trackMetric.standardDeviationSpeed = sqrt(var(velosities));
trackMetric.meanArea = mean(areas);
trackMetric.minArea = min(areas);
trackMetric.maxArea = max(areas);
trackMetric.standardDeviationArea = sqrt(var(areas));
trackMetric.meanIntesity = mean(intensities);
trackMetric.standardDeviationIntesity = sqrt(var(intensities));
end