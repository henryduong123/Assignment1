%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
%     This file is part of LEVer.exe
%     (C) 2011 Andrew Cohen, Eric Wait and Mark Winter
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


global CONSTANTS;

CONSTANTS=[];

InitializeConstants();

directory_name = uigetdir('','Select Root Folder for Seg and Track');
if(~directory_name),return,end

dlist=dir(directory_name);
for dd=1:length(dlist)
    
    if ~(dlist(dd).isdir),continue,end
 
    fileList = dir([directory_name '\' dlist(dd).name '\*.tif']);
    numberOfImages = length(fileList);

    if 0==numberOfImages,continue,end
        
    CONSTANTS.rootImageFolder=[directory_name '\' dlist(dd).name '\'];
    CONSTANTS.datasetName=dlist(dd).name;
    CONSTANTS.matFullFile=[directory_name '\' CONSTANTS.datasetName '_LEVer.mat'];
    if exist(CONSTANTS.matFullFile,'file'),continue,end
    TouchFile=[];
    save(CONSTANTS.matFullFile,'TouchFile');
    
    tic
    imageAlpha=1.5;
    %get image significant digits
    CONSTANTS.imageSignificantDigits=ceil(log10(numberOfImages));
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
        system(['start Segmentor ' num2str(i) ' ' num2str(numProcessors) ' ' ...
            num2str(numberOfImages) ' "' CONSTANTS.rootImageFolder(1:end-1) '" "' CONSTANTS.datasetName '" ' ...
            num2str(imageAlpha) ' ' num2str(CONSTANTS.imageSignificantDigits) ' && exit']); 
        %use line below instead of the 3 lines above for non-parallel or to debug
    %     Segmentor(i,numProcessors,numberOfImages,CONSTANTS.rootImageFolder(1:end-1),CONSTANTS.datasetName,CONSTANTS.imageAlpha,CONSTANTS.imageSignificantDigits);
    end

    for i=1:numProcessors
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

    segtimes = [cellSegments.t];
    [srtseg srtidx] = sort(segtimes);
    cellSegments = cellSegments(srtidx);

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
    system(['.\MTC.exe "' fnameIn '" "' fnameOut '" > out.txt']);
    fprintf('Done\n');
    tTrack=toc;

    %% Inport into LEVer's data sturcture
    [objHulls gConnect HashedHulls] = ReadTrackData(cellSegments,CONSTANTS.datasetName);

    fprintf('Finalizing Data...');
    ConvertTrackingData(objHulls,gConnect);
    fprintf('Done\n');
    
    SaveLEVerState([CONSTANTS.matFullFile]);



end %dd



