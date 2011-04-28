function ExportAITPD(src,evnt)

global CellTracks CONSTANTS

cells = [];
for i = 1:length(CellTracks)
    cells = [cells compileTrackData(CellTracks(i),i)];
end

load('LEVerSettings.mat');
[file,filePath,filterIndex] = uiputfile([settings.matFilePath '*.mat'],'Save data',...
        [CONSTANTS.datasetName '_AITPD.mat']);
if(filterIndex<1),return,end
save([filePath file],'cells');
end

function trackData = compileTrackData(track,label)
global CONSTANTS CellPhenotypes CellHulls

trackData.datasetName = CONSTANTS.datasetName;
trackData.cellLabel = label;
trackData.parent = track.parentTrack;
trackData.sibling = track.siblingTrack;
trackData.children = track.childrenTracks;
trackData.timeOfDeath = track.timeOfDeath;
if(track.phenotype)
    trackData.phenotype = CellPhenotypes.descriptions{track.phenotype};
else
    trackData.phenotype = '';
end

trackData.FeatureLabels(1) = 'area';
trackData.FeatureLabels(2) = 'mu_intensity';
trackData.FeatureLabels(3) = 'sd_intensity';
trackData.FeatureLabels(4) = 'speed';
trackData.FeatureLabels(5) = 'direction';
trackData.FeatureLabels(6) = 'eccentricity';

for i=1:length(track.hulls)
    if(~track.hulls(i)),continue,end

    trackData.times(length(trackData.times)+1,1) = track.startTime +i -1;
    trackData.Features(1) = length(CellHulls(track.hulls(i)).indexPixels);
    trackData.Features(2) = mean(CellHulls(track.hulls(i)).imagePixels);
    trackData.Features(3) = sqrt(var(CellHulls(track.hulls(i)).imagePixels));
    
    j = i-1;
    if(~j),continue,end
    if(~track.hulls(j)) %find the previous frame where a hull exits
        for k=j:-1:1
            if(track.hulls(k)),break,end
        end
        if(~track.hulls(k)),break,end %reached the beginning
        j = k;
    end
    dx = CellHulls(track.hulls(i)).centerOfMass(1)-CellHulls(track.hulls(j)).centerOfMass(1);
    dy = CellHulls(track.hulls(i)).centerOfMass(2)-CellHulls(track.hulls(j)).centerOfMass(2);
    dist = sqrt(dx^2 + dy^2);
    trackData.Features(4) = dist/(i-j);
    trackData.Features(5) = atan2(dy,dy);
    im = zeros(CONSTANTS.imageSize);
    im(ind2sub(2,trackData.indexPixels)) = 1;
    trackData.
    
end
end