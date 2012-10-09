function [status tSeg tTrack] = SegAndTrackDataset(rootFolder, datasetName, imageAlpha, sigDigits, numProcessors)
    global CONSTANTS
    
    status = 1;
    tSeg = 0;
    tTrack = 0;

    %% Segmentation
    tic
    
    fileList = dir(fullfile(rootFolder, [datasetName '*.tif']));
    numberOfImages = length(fileList);
    
    if ( numberOfImages < 1 )
        return;
    end

    cellSegments = [];
    cellFeat = [];
    cellSegLevels = [];

    fprintf('Segmenting (using %s processors)...\n',num2str(numProcessors));

    if(~isempty(dir('.\segmentationData')))
        errFile = '.\segmentationData\err_*.log';
        fileName = '.\segmentationData\objs_*.mat';
        semFile = '.\segmentationData\done_*.txt';
        system(['del /Q ' errFile ' ' fileName ' ' semFile]);
%         system('rmdir /S /Q .\segmentationData');
    end
    
    % Set CONSTANTS.imageSize as soon as possible
    firstImg = Helper.GetFullImagePath(1);
    chkIm = Helper.LoadIntensityImage(firstImg);
    CONSTANTS.imageSize = size(chkIm);
    
    if ( ndims(CONSTANTS.imageSize) ~= 2 )
        cltime = clock();
        errlog = fopen([datasetName '_seg_error.log'], 'w');
        fprintf(errlog, '%02d:%02d:%02.1f - Images are empty or have incorrect dimensions [%s]\n',cltime(4),cltime(5),cltime(6), num2str(CONSTANTS.imageSize));
        fclose(errlog);
        return;
    end
    
    if(isempty(dir('.\segmentationData')))
        system('mkdir .\segmentationData');
    end
    
    dirName = fileparts(CONSTANTS.rootImageFolder);
    for i=1:numProcessors
         system(['start Segmentor ' num2str(i) ' ' num2str(numProcessors) ' ' ...
            num2str(numberOfImages) ' ' CONSTANTS.cellType ' ' ...
            num2str(imageAlpha) ' "' dirName '" ' CONSTANTS.imageNamePattern ' && exit']);
        %use line below instead of the 3 lines above for non-parallel or to debug
%         Segmentor(i,numProcessors,numberOfImages,CONSTANTS.cellType,imageAlpha,dirName,CONSTANTS.imageNamePattern);
    end

    bSegFileExists = false(1,numProcessors);
    for i=1:numProcessors
        errFile = ['.\segmentationData\err_' num2str(i) '.log'];
        fileName = ['.\segmentationData\objs_' num2str(i) '.mat'];
        semFile = ['.\segmentationData\done_' num2str(i) '.txt'];
        semDesc = dir(semFile);
        fileDescriptor = dir(fileName);
        efd = dir(errFile);
        while((isempty(fileDescriptor) || isempty(semDesc)) && isempty(efd))
            pause(3)
            fileDescriptor = dir(fileName);
            efd = dir(errFile);
            semDesc = dir(semFile);
        end
        
        bSegFileExists(i) = ~isempty(fileDescriptor);
    end
    
    if ( ~all(bSegFileExists) )
        status = 1;
        tSeg = toc;
        
        % Collect segmentation error logs into one place
        errlog = fopen([datasetName '_seg_error.log'], 'w');
        for i=1:length(bSegFileExists)
            if ( bSegFileExists )
                continue;
            end
            fprintf(errlog, '----------------------------------\n');
            objerr = fopen(fullfile('.','segmentationData',['err_' num2str(i) '.log']));
            logline = fgetl(objerr);
            while ( ischar(logline) )
                fprintf(errlog, '%s\n', logline);
                logline = fgetl(objerr);
            end
            fclose(objerr);
        end
        fclose(errlog);
        
        return;
    end

    try
        leveltimes = [];
        for i=1:numProcessors
            fileName = ['.\segmentationData\objs_' num2str(i) '.mat'];
            
            tst = whos('-file', fileName);
            
            load(fileName);
            
            cellSegments = [cellSegments objs];
            cellFeat = [cellFeat features];
            cellSegLevels = [cellSegLevels levels];
            leveltimes = [leveltimes unique([objs.t])];
            
            pause(1)
        end
    catch excp
        
        cltime = clock();
        errlog = fopen([datasetName '_seg_error.log'], 'w');
        fprintf(errlog, '%02d:%02d:%02.1f - Problem loading segmentation\n',cltime(4),cltime(5),cltime(6));
        Error.PrintException(errlog, excp);
        fclose(errlog);
        
        status = 1;
        tSeg = toc;
        return;
    end

    segtimes = [cellSegments.t];
    [srtseg srtidx] = sort(segtimes);
    cellSegments = cellSegments(srtidx);
    cellFeat = cellFeat(srtidx);

    [srtlevels srtidx] = sort(leveltimes);
    cellSegLevels = cellSegLevels(srtidx);

    fprintf('Please wait...');

    cellSegments = Tracker.GetDarkConnectedHulls(cellSegments);
%     save ( ['.\segmentationData\SegObjs_' datasetName '.mat'],'cellSegments');
    Segmentation.WriteSegData(cellSegments,datasetName);

    fprintf(1,'\nDone\n');

    fnameIn=['.\segmentationData\SegObjs_' datasetName '.txt'];
    fnameOut=['.\segmentationData\Tracked_' datasetName '.txt'];
    tSeg=toc;

    %% Tracking
    tic
    fprintf(1,'Tracking...');
    system(['.\MTC.exe ' num2str(CONSTANTS.dMaxCenterOfMass) ' ' num2str(CONSTANTS.dMaxConnectComponentTracker) ' "' fnameIn '" "' fnameOut '" > out.txt']);
    fprintf('Done\n');
    tTrack=toc;

    %% Inport into LEVer's data sturcture
    [objHulls gConnect HashedHulls] = Tracker.ReadTrackData(CONSTANTS.imageSize, cellSegments, datasetName);

    fprintf('Finalizing Data...');
    try
        Tracker.ConvertTrackingData(objHulls,gConnect);
    catch excp
        
        cltime = clock();
        errlog = fopen([datasetName '_seg_error.log'], 'w');
        fprintf(errlog, '%02d:%02d:%02.1f - Problem building LEVER structures\n',cltime(4),cltime(5),cltime(6));
        Error.PrintException(errlog, excp);
        fclose(errlog);
        
        status = 1;
        return;
    end
    
    fprintf('Done\n');
    
    clear cellSegments;
    clear cellFeat;
    clear cellSegLevels;
    clear leveltimes;
    
    status = 0;
end