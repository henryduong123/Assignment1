function SegAndTrack()
global CONSTANTS

%% Segmentation
tic

fileList = dir([CONSTANTS.rootImageFolder CONSTANTS.imageDatasetName '*.tif']);
numberOfImages = length(fileList);

cellSegments = [];
numProcessors = getenv('Number_of_processors');
numProcessors = str2double(numProcessors);
if(isempty(numProcessors) || isnan(numProcessors)),numProcessors = 2;end

fprintf('Segmenting (using %s processors)...\n',num2str(numProcessors));

step = ceil(numberOfImages/numProcessors);

if(~isempty(dir('.\segmentationData')))
    system('rmdir /S /Q .\segmentationData');
end

for timeStart=1:step:numberOfImages
    system(['start Segmentor ' num2str(timeStart) ' ' num2str(step-1) ' "' ...
        CONSTANTS.rootImageFolder(1:end-1) '" ' CONSTANTS.datasetName ' ' ...
        num2str(CONSTANTS.imageAlpha) ' ' num2str(CONSTANTS.imageSignificantDigits) ' && exit']);
end

for i=1:step:numberOfImages
    fileName = ['.\segmentationData\objs_' num2str(i) '.mat'];
    fileDescriptor = dir(fileName);
    while(isempty(fileDescriptor))
        pause(1)
        fileDescriptor = dir(fileName);
    end
    pause(2)
end

for i=1:step:numberOfImages
    fileName = ['.\segmentationData\objs_' num2str(i) '.mat'];
    load(fileName);
    cellSegments = [cellSegments objs];
    pause(1)
end

fprintf('Please wait...');

cellSegments = GetDarkConnectedHulls(cellSegments);
save ( ['SegObjs_' CONSTANTS.datasetName '.mat'],'cellSegments');
WriteSegData(cellSegments,CONSTANTS.datasetName);

fprintf(1,'\nDone\n');

load ( ['SegObjs_' CONSTANTS.datasetName '.mat']);
fnameIn=['SegObjs_' CONSTANTS.datasetName '.txt'];
fnameOut=['Tracked_' CONSTANTS.datasetName '.txt'];
tSeg=toc;

%% Tracking
tic
fprintf(1,'Tracking...');
system(['.\MTC.exe ' fnameIn ' ' fnameOut ' > out.txt']);
fprintf('Done\n');
tTrack=toc;

%% Inport into LEVer's data sturcture
[objHulls gConnect HashedHulls] = ReadTrackData(cellSegments,CONSTANTS.datasetName);

fprintf('Finalizing Data...');
ConvertTrackingData(objHulls,gConnect);
fprintf('Done\n');

InitializeFigures();

SaveDataAs();

LogAction('Segmentation time - Tracking time',tSeg,tTrack);
end