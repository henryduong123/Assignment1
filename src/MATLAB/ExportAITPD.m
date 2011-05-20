%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
%     This file is part of LEVer.exe
%     (C) 2011 Andrew Cohen, Eric Wait and Mark Winter
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function ExportAITPD(src,evnt)

global CellTracks Figures CellPhenotypes

History('Push');
LogAction('Classifing according to AITPD');

Trellis = [];
progress = 1;
iterations = length(CellTracks);
for i = 1:length(CellTracks)
    progress = progress+1;
    Progressbar(progress/iterations);
    if(isempty(CellTracks(i).familyID)),continue,end
    Trellis = [Trellis compileTrackData(CellTracks(i),i)];
end
Progressbar(1);%clear it out

good = writeOutAITPDtxt(Trellis);
if(~good)
    History('Pop');
    return
end

Progressbar(1);%clear it out

msgbox('Next part will take some time depending on the size of the dataset.  A second window will popup when this is finished');

[status, result] = system('GenerateDistanceMatrices.exe .\AITPDData\Trellis.txt .\AITPDData\distances > distGenLog.txt');
if(~status)
    msgbox('AITPD Failed');
    History('Pop');
    return
end
[status, result] = system('GapSpectral.exe .\AITPDData\distances > stats.txt');
if(~status)
    msgbox('AITPD Failed');
    History('Pop');
    return
end

f = fopen('stats.txt','r');
m = fscanf(f,'%s');
fs = findstr(m,'f=');
Ns = findstr(m,'N=');
ks = findstr(m,'kgap=');
gs = findstr(m,'gamma=');
cs = findstr(m,'classes=');
t = findstr(m,'time');

fcom = findstr(m(fs(end):end),',');
Ncom = findstr(m(Ns(end):end),',');
kcom = findstr(m(ks(end):end),',');
gcom = findstr(m(gs(end):end),',');

F = str2double(m(fs(end)+2:fs(end)+fcom(1)-2));
N = str2double(m(Ns(end)+2:Ns(end)+Ncom(1)-2));
k = str2double(m(ks(end)+5:ks(end)+kcom(1)-2));
gamma = str2double(m(gs(end)+6:gs(end)+gcom(1)-2));

c = m(cs(end)+8:t-1);
com = findstr(c,',');
class = str2double(c(1:com(1)-1));
for i=1:length(com)-1
    class = [class str2double(c(com(i)+1:com(i+1)-1))];
end

phenoNum = length(CellPhenotypes.descriptions);

for i=1:k
    AddPhenotype({['class' num2str(i)]});
end

msgbox(['F=' num2str(F) ', N=' num2str(N) ', k=' num2str(k) ', gamma=' num2str(gamma)]);

for i=1:length(Trellis)
    CellTracks(Trellis(i).cellLabel).phenotype = class(i)+phenoNum+1;
end

DrawTree(Figures.tree.familyID); 
end

function trackData = compileTrackData(track,label)
global CONSTANTS CellPhenotypes CellHulls CellFamilies HashedCells

trackData = [];

if(CellFamilies(track.familyID).endTime-CellFamilies(track.familyID).startTime < 0.50*length(HashedCells)),return,end

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

trackData.FeatureLabels = {'Area','ConvexArea','MeanIntensity','SD_Intensity','Eccentricity','Speed','Direction'};
trackData.times = [];
trackData.Features = [];

featureIndex = 1;

for i=1:length(track.hulls)
    j = i+1;
    if(j>length(track.hulls)),continue,end
    if(~track.hulls(j)) %find the previous frame where a hull exits
        for k=j:length(track.hulls)
            if(track.hulls(k)),break,end
        end
        if(~track.hulls(k)),break,end %reached the beginning
        j = k;
    end
    if(~track.hulls(i) || ~j || j>length(track.hulls)),continue,end
    
    trackData.times(length(trackData.times)+1,1) = track.startTime +i -1;
    
    [x y] = ind2sub(CONSTANTS.imageSize,CellHulls(track.hulls(i)).indexPixels);
    x = x(:) - min(x) +2;
    y = y(:) - min(y) +2;
    im = zeros(max(x)+2,max(y)+2);
    im(x,y) = 1;
    stats = regionprops(im,'Eccentricity','Area','ConvexArea');
    
    trackData.Features(featureIndex,1) = stats.Area;
    trackData.Features(featureIndex,2) = stats.ConvexArea;
    trackData.Features(featureIndex,3) = mean(CellHulls(track.hulls(i)).imagePixels);
    trackData.Features(featureIndex,4) = sqrt(var(CellHulls(track.hulls(i)).imagePixels));
    trackData.Features(featureIndex,5) = stats.Eccentricity;
    
    dx = CellHulls(track.hulls(j)).centerOfMass(1)-CellHulls(track.hulls(i)).centerOfMass(1);
    dy = CellHulls(track.hulls(j)).centerOfMass(2)-CellHulls(track.hulls(i)).centerOfMass(2);
    dist = sqrt(dx^2 + dy^2);
    trackData.Features(featureIndex,6) = dist/(j-i);
    trackData.Features(featureIndex,7) = atan2(dy,dx);
    featureIndex = featureIndex+1;
end
end

function success = writeOutAITPDtxt(Trellis)
global CONSTANTS

success = 0;

progress = 1;
iterations = length(Trellis);

Progressbar(progress/iterations);

if(~isempty(dir('.\AITPDData')))
    system('rmdir /S /Q .\AITPDData');
end
if(isempty(dir('.\AITPDData'))),system('mkdir .\AITPDData');end
filePath = '.\AITPDData\';
file = 'Trellis.txt';

% load('LEVerSettings.mat');
% [file,filePath,filterIndex] = uiputfile([settings.matFilePath '*.txt'],'Save data',...
%         [CONSTANTS.datasetName '_AITPD.txt']);
% if(filterIndex<1),return,end

fout=fopen([filePath file],'w');
[m n]=cellfun(@size,{Trellis.Features});
fprintf(fout,'%d,%d\n',length(Trellis),sum(m)*n(1));

for i=1:length(Trellis)
    progress = progress+1;
    Progressbar(progress/iterations);
    fprintf(fout,'%d,%d\n',size(Trellis(i).Features,1),size(Trellis(i).Features,2));
    for j=1:size(Trellis(i).Features,1)
        for k=1:size(Trellis(i).Features,2)
            fprintf(fout,'%f,',Trellis(i).Features(j,k));
        end
        fprintf(fout,'\n');
    end
end
fclose(fout);

success = 1;
end