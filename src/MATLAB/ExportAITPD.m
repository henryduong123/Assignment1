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

for i=1:length(track.hulls)
    if(~track.hulls(i)),continue,end

    trackData.hulls(i).time = track.startTime +i -1;
    trackData.hulls(i).area = length(CellHulls(track.hulls(i)).indexPixels);
    trackData.hulls(i).meanIntensity = mean(CellHulls(track.hulls(i)).imagePixels);
    trackData.hulls(i).sdIntensity = sqrt(var(CellHulls(track.hulls(i)).imagePixels));
    
    j = i-1;
    if(~j),continue,end
    if(~track.hulls(j)) %find the previous frame where a hull exits
        for k=j:-1:1
            if(track.hulls(k)),break,end
        end
        if(~track.hulls(k)),break,end %reached the beginning
        j = k;
    end
    dist = sqrt((CellHulls(track.hulls(i)).centerOfMass(1)-CellHulls(track.hulls(j)).centerOfMass(1))^2 + ...
        (CellHulls(track.hulls(i)).centerOfMass(2)-CellHulls(track.hulls(j)).centerOfMass(2))^2);
    trackData.hulls(i).speed = dist/(i-j);
end
end