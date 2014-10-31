function [errStatus tSeg tTrack] = SegAndTrackDataset(rootFolder, datasetName, namePattern, numProcessors, segArgs)
    global CONSTANTS
    
    errStatus = sprintf('Unknown Error\n');
    tSeg = 0;
    tTrack = 0;

    %% Segmentation
    tic
    
    % Remove trailing \ or / from rootFolder
    if ( (rootFolder(end) == '\') || (rootFolder(end) == '/') )
        rootFolder = rootFolder(1:end-1);
    end
    
    numProcessors = min(numProcessors, numFrames);
    
    if ( numFrames < 1 )
        return;
    end

    cellSegments = [];
    cellFeat = [];
    cellSegLevels = [];

    fprintf('Segmenting (using %s processors)...\n',num2str(numProcessors));

    if(~isempty(dir('.\segmentationData')))        
        removeOldFiles('segmentationData', 'err_*.log');
        removeOldFiles('segmentationData', 'objs_*.mat');
        removeOldFiles('segmentationData', 'done_*.txt');
    end
    
    % Set CONSTANTS.imageSize as soon as possible
    [numChannels numFrames] = Helper.GetImListInfo(CONSTANTS.rootImageFolder, CONSTANTS.imageNamePattern);
    imSet = Helper.LoadIntensityImageSet(1);

    imSizes = zeros(length(imSet),2);
    for i=1:length(imSet)
        imSizes(i,:) = size(imSet{i});
    end

    Load.AddConstant('imageSize', max(imSizes,[],1),1);
    Load.AddConstant('numFrames', numFrames,1);
    Load.AddConstant('numChannels', numChannels,1);
    
    if ( ndims(CONSTANTS.imageSize) < 2 || ndims(CONSTANTS.imageSize) > 3 )
        cltime = clock();
        errStatus = sprintf('%02d:%02d:%02.1f - Images are empty or have incorrect dimensions [%s]\n',cltime(4),cltime(5),cltime(6), num2str(CONSTANTS.imageSize));
        
        return;
    end
    
    if ( ~exist('.\segmentationData','dir'))
        mkdir('segmentationData');
    end
    
    if ( isdeployed() )
        for procID=1:numProcessors
            segCmd = makeSegCommand(procID,numProcessors,numChannels,numFrames,CONSTANTS.cellType,rootFolder,namePattern,segArgs);
            system(['start ' segCmd ' && exit']);
        end
    else
        matlabpool(numProcessors)
        parfor procID=1:numProcessors
            Segmentor(procID,numProcessors,numChannels,numFrames,CONSTANTS.cellType,rootFolder,namePattern,segArgs{:});
        end
    end

    bSegFileExists = false(1,numProcessors);
    for procID=1:numProcessors
        errFile = ['.\segmentationData\err_' num2str(procID) '.log'];
        fileName = ['.\segmentationData\objs_' num2str(procID) '.mat'];
        semFile = ['.\segmentationData\done_' num2str(procID) '.txt'];
        semDesc = dir(semFile);
        fileDescriptor = dir(fileName);
        efd = dir(errFile);
        while((isempty(fileDescriptor) || isempty(semDesc)) && isempty(efd))
            pause(3)
            fileDescriptor = dir(fileName);
            efd = dir(errFile);
            semDesc = dir(semFile);
        end
        
        bSegFileExists(procID) = ~isempty(fileDescriptor);
    end
    
    if ( ~all(bSegFileExists) )
        errStatus = '';
        tSeg = toc;
        
        % Collect segmentation error logs into one place
        for procID=1:length(bSegFileExists)
            if ( bSegFileExists(procID) )
                continue;
            end
            
            errStatus = sprintf( '----------------------------------\n');
            objerr = fopen(fullfile('.','segmentationData',['err_' num2str(procID) '.log']));
            logline = fgetl(objerr);
            while ( ischar(logline) )
                errStatus = [errStatus sprintf('%s\n', logline)];
                logline = fgetl(objerr);
            end
            fclose(objerr);
        end
        
        return;
    end

    try
        leveltimes = [];
        for procID=1:numProcessors
            fileName = ['.\segmentationData\objs_' num2str(procID) '.mat'];
            
            tstLoad = whos('-file', fileName);
            
            load(fileName);
            
            cellSegments = [cellSegments objs];
            cellFeat = [cellFeat features];
            cellSegLevels = [cellSegLevels levels];
            leveltimes = [leveltimes unique([objs.t])];
            
            pause(1)
        end
    catch excp
        
        cltime = clock();
        errStatus = sprintf('%02d:%02d:%02.1f - Problem loading segmentation\n',cltime(4),cltime(5),cltime(6));
        errStatus = [errStatus Error.PrintException(excp)];
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
        errStatus = sprintf('%02d:%02d:%02.1f - Problem building LEVER structures\n',cltime(4),cltime(5),cltime(6));
        errStatus = [errStatus Error.PrintException(excp)];
        
        return;
    end
    
    fprintf('Done\n');
    
    clear cellSegments;
    clear cellFeat;
    clear cellSegLevels;
    clear leveltimes;
    
    errStatus = '';
end

function segCmd = makeSegCommand(procID, numProc, numFrames, cellType, rootFolder, imagePattern, segArg)
    segCmd = 'Segmentor';
    segCmd = [segCmd ' "' num2str(procID) '"'];
    segCmd = [segCmd ' "' num2str(numProc) '"'];
    segCmd = [segCmd ' "' num2str(numFrames) '"'];
    segCmd = [segCmd ' "' cellType '"'];
    segCmd = [segCmd ' "' rootFolder '"'];
    segCmd = [segCmd ' "' imagePattern '"'];
    
    for i=1:length(segArg)
        segCmd = [segCmd ' "' num2str(segArg{i}) '"'];
    end
end

function removeOldFiles(rootDir, filePattern)
    flist = dir(fullfile(rootDir,filePattern));
    for i=1:length(flist)
        if ( flist(i).isdir )
            continue;
        end
        
        delete(fullfile(rootDir,flist(i).name));
    end
end
