function status = SegAndTrack()
global CONSTANTS

status = 0;

if (exist('LEVerSettings.mat','file')~=0)
        load('LEVerSettings.mat');
else
    settings.matFilePath = '.\';
end

[settings.matFile,settings.matFilePath,FilterIndex] = uiputfile('.mat','Save edits',...
    [CONSTANTS.imageDatasetName '_LEVer.mat']);

if(~FilterIndex),return,end

status = 1;

save('LEVerSettings.mat','settings');

%% Segmentation
tic

fileList = dir([CONSTANTS.rootImageFolder CONSTANTS.imageDatasetName '*.tif']);
numberOfImages = length(fileList);

cellSegments = [];
numProcessors = getenv('Number_of_processors');
numProcessors = str2double(numProcessors);
if(isempty(numProcessors) || isnan(numProcessors) || numProcessors<4),numProcessors = 4;end

fprintf('Segmenting (using %s processors)...\n',num2str(numProcessors));

% step = ceil(numberOfImages/numProcessors);

if(~isempty(dir('.\segmentationData')))
    system('rmdir /S /Q .\segmentationData');
end

for i=1:numProcessors
%     system(['start Segmentor ' num2str(timeStart) ' ' num2str(step-1) ' "' ...
%         CONSTANTS.rootImageFolder(1:end-1) '" ' CONSTANTS.datasetName ' ' ...
%         num2str(CONSTANTS.imageAlpha) ' ' num2str(CONSTANTS.imageSignificantDigits) ' && exit']);
    %use line below instead of the 3 lines above for non-parallel or to debug
    Segmentor(i,numProcessors,numberOfImages,CONSTANTS.rootImageFolder(1:end-1),CONSTANTS.datasetName,CONSTANTS.imageAlpha,CONSTANTS.imageSignificantDigits);
end

parfor i=1:numProcessors
    fileName = ['.\segmentationData\objs_' num2str(i) '.mat'];
    fileDescriptor = dir(fileName);
    while(isempty(fileDescriptor))
        pause(3)
        fileDescriptor = dir(fileName);
    end
end

for i=1:numProcessors
    fileName = ['.\segmentationData\objs_' num2str(i) '.mat'];
    load(fileName);
    cellSegments = [cellSegments objs];
    pause(1)
end

fprintf('Please wait...');

cellSegments = GetDarkConnectedHulls(cellSegments);
save ( ['.\segmentationData\SegObjs_' CONSTANTS.datasetName '.mat'],'cellSegments');
WriteSegData(cellSegments,CONSTANTS.datasetName);

fprintf(1,'\nDone\n');

fnameIn=['.\segmentationData\SegObjs_' CONSTANTS.datasetName '.txt'];
fnameOut=['.\segmentationData\Tracked_' CONSTANTS.datasetName '.txt'];
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

SaveData();

LogAction('Segmentation time - Tracking time',tSeg,tTrack);
end