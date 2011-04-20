function ExportMetrics(src,evnt)

global CellTracks CONSTANTS

trackMetrics = [];

for i=1:length(CellTracks)
    trackMetrics = [trackMetrics getMetrics(i,CellTracks(i))];
end

data = 'Cell Label,Number of Frames,Parent,Child 1,Child 2,Dies on Frame,Mean Speed,Speed Variance,Min Speed,Max Speed,Mean Area,Variance Area,Min Area,Max Area,Mean Pixel Intensities,Variance Pixel Intensities\n';
for i=1:length(trackMetrics)
    data = [data num2str(trackMetrics(i).trackID) ',' num2str(trackMetrics(i).timeFrame) ','];
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
    if(~isempty(trackMetrics(i).death))
        data = [data num2str(trackMetrics(i).death) ','];
    else
        data = [data ','];
    end
    data = [data num2str(trackMetrics(i).meanSpeed) ',' num2str(trackMetrics(i).varianceSpeed) ','...
        num2str(trackMetrics(i).minSpeed) ',' num2str(trackMetrics(i).maxSpeed) ','...
        num2str(trackMetrics(i).meanArea) ',' num2str(trackMetrics(i).varianceArea) ','...
        num2str(trackMetrics(i).minArea) ',' num2str(trackMetrics(i).maxArea) ','...
        num2str(trackMetrics(i).meanIntesity) ',' num2str(trackMetrics(i).varianceIntesity) '\n'];
end

load('LEVerSettings.mat');
file = fopen([settings.matFilePath CONSTANTS.datasetName '_metrics.csv'],'w');
fprintf(file,data);
fclose(file);
end

function trackMetric = getMetrics(trackID,track)
global CellHulls

trackMetric = [];
if(length(track.hulls)<3),return,end

trackMetric.trackID = trackID;
trackMetric.timeFrame = length(track.hulls);
trackMetric.parent = track.parentTrack;
trackMetric.children = track.childrenTracks;
trackMetric.death = track.timeOfDeath;

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
trackMetric.varianceSpeed = var(velosities);
trackMetric.meanArea = mean(areas);
trackMetric.minArea = min(areas);
trackMetric.maxArea = max(areas);
trackMetric.varianceArea = var(areas);
trackMetric.meanIntesity = mean(intensities);
trackMetric.varianceIntesity = var(intensities);
end