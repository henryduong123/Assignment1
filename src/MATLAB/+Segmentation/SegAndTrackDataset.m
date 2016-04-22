function [errStatus,tSeg,tTrack] = SegAndTrackDataset(numProcessors, segArgs)
    global CONSTANTS CellHulls HashedCells ConnectedDist
    
    errStatus = sprintf('Unknown Error\n');
    tSeg = 0;
    tTrack = 0;

    %% Segmentation
    tic
    
    if ( Metadata.GetNumberOfFrames() < 1 )
        return;
    end
    
    numProcessors = min(numProcessors, Metadata.GetNumberOfFrames());

    numProcessors = min(numProcessors, Metadata.GetNumberOfFrames());
    bytesPerIm = prod(Metadata.GetDimensions()) * Metadata.GetNumberOfChannels() * 8;
    m = memory;
    maxWorkers = min(numProcessors,floor(m.MaxPossibleArrayBytes / bytesPerIm));

    % Remove trailing \ or / from rootFolder
    if ( (CONSTANTS.rootImageFolder(end) == '\') || (CONSTANTS.rootImageFolder(end) == '/') )
        CONSTANTS.rootImageFolder = CONSTANTS.rootImageFolder(1:end-1);
    end

    fprintf('Segmenting (using %s processors)...\n',num2str(maxWorkers));

    if(~isempty(dir('.\segmentationData')))        
        removeOldFiles('segmentationData', 'err_*.log');
        removeOldFiles('segmentationData', 'objs_*.mat');
        removeOldFiles('segmentationData', 'done_*.txt');
    end
    
    if ( isempty(Metadata.GetDimensions()) )
        cltime = clock();
        errStatus = sprintf('%02d:%02d:%02.1f - Images dimensions are empty\n',cltime(4),cltime(5),cltime(6));
        
        return;
    end
    
    if ( ~exist('.\segmentationData','dir'))
        mkdir('segmentationData');
    end
    
    metadataFile = fullfile(CONSTANTS.rootImageFolder, [Metadata.GetDatasetName() '.json']);
    primaryChannel = CONSTANTS.primaryChannel;
    cellType = CONSTANTS.cellType;
    
    if ( isdeployed() )
        %% compliled version
        % Must use separately compiled segmentor algorithm in compiled LEVer
        % because parallel processing toolkit is unsupported
        for procID=1:maxWorkers
            segCmd = makeSegCommand(procID,maxWorkers,primaryChannel,metadataFile,cellType,segArgs);
            system(['start ' segCmd ' && exit']);
        end
    else
        %% single threaded version
%         for procID=1:maxWorkers
%             Segmentor(procID,maxWorkers,primaryChannel,metadataFile,cellType,segArgs{:});
%         end

        %% spmd version
        poolObj = gcp('nocreate');
        if (~isempty(poolObj))
            oldWorkers = poolObj.NumWorkers;
            if (oldWorkers~=maxWorkers)
                delete(poolObj);
                parpool(maxWorkers);
            end
        else
            oldWorkers = 0;
            parpool(maxWorkers);
        end

        spmd
            Segmentor(labindex,numlabs,primaryChannel,metadataFile,cellType,segArgs{:});
        end

        if (oldWorkers~=0 && oldWorkers~=maxWorkers)
            delete(gcp);
            if (oldWorkers>0)
                parpool(oldWorkers);
            end
        end
    end
    
    %% collate output
    bSegFileExists = false(1,maxWorkers);
    bSemFileExists = false(1,maxWorkers);
    bErrFileExists = false(1,maxWorkers);
    
    bProcFinish = false(1,maxWorkers);
    while ( ~all(bProcFinish) )
        pause(3);
        
        for procID=1:maxWorkers
            errFile = ['.\segmentationData\err_' num2str(procID) '.log'];
            segFile = ['.\segmentationData\objs_' num2str(procID) '.mat'];
            semFile = ['.\segmentationData\done_' num2str(procID) '.txt'];
            
            bErrFileExists(procID) = ~isempty(dir(errFile));
            bSegFileExists(procID) = ~isempty(dir(segFile));
            bSemFileExists(procID) = ~isempty(dir(semFile));
        end
        
        bProcFinish = bErrFileExists | (bSegFileExists & bSemFileExists);
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
        cellSegments = [];
        for procID=1:maxWorkers
            segFile = ['.\segmentationData\objs_' num2str(procID) '.mat'];
            
            tstLoad = whos('-file', segFile);
            
            load(segFile);
            
            cellSegments = [cellSegments hulls];
        end
    catch excp
        
        cltime = clock();
        errStatus = sprintf('%02d:%02d:%02.1f - Problem loading segmentation\n',cltime(4),cltime(5),cltime(6));
        errStatus = [errStatus Error.PrintException(excp)];
        tSeg = toc;
        return;
    end
    
    if ( isempty(cellSegments) )
        cltime = clock();
        errStatus = sprintf('%02d:%02d:%02.1f - No segmentations found\n',cltime(4),cltime(5),cltime(6));
        tSeg = toc;
        return;
    end

    % Sort segmentations and fluorescent data so that they are time ordered
    segtimes = [cellSegments.time];
    [srtSegs srtIdx] = sort(segtimes);
    CellHulls = Helper.MakeInitStruct(Helper.GetCellHullTemplate(), cellSegments(srtIdx));
    
    % Make sure center of mass is available
    for i=1:length(CellHulls)
        [r c] = ind2sub(Metadata.GetDimensions('rc'), CellHulls(i).indexPixels);
        CellHulls(i).centerOfMass = mean([r c], 1);
    end
    
    fprintf('Building Connected Component Distances... ');
    HashedCells = cell(1,Metadata.GetNumberOfFrames());
    for t=1:Metadata.GetNumberOfFrames()
        HashedCells{t} = struct('hullID',{}, 'trackID',{});
    end
    
    for i=1:length(CellHulls)
        HashedCells{CellHulls(i).time} = [HashedCells{CellHulls(i).time} struct('hullID',{i}, 'trackID',{0})];
    end
    
    ConnectedDist = [];
    Tracker.BuildConnectedDistance(1:length(CellHulls), 0, 1);
    Segmentation.WriteSegData('segmentationData',Metadata.GetDatasetName());

    fprintf(1,'\nDone\n');
    tSeg = toc;

    %% Tracking
    tic
    fprintf(1,'Tracking...');
    fnameIn=['.\segmentationData\SegObjs_' Metadata.GetDatasetName() '.txt'];
    fnameOut=['.\segmentationData\Tracked_' Metadata.GetDatasetName() '.txt'];
    
    system(['MTC.exe ' num2str(CONSTANTS.dMaxCenterOfMass) ' ' num2str(CONSTANTS.dMaxConnectComponentTracker) ' "' fnameIn '" "' fnameOut '" > out.txt']);
    
    fprintf('Done\n');
    tTrack = toc;

    %% Import into LEVer's data sturcture
    [objTracks gConnect] = Tracker.ReadTrackData('segmentationData', Metadata.GetDatasetName());
    fprintf('Finalizing Data...');
    try
        Tracker.BuildTrackingData(objTracks, gConnect);
    catch excp
        
        cltime = clock();
        errStatus = sprintf('%02d:%02d:%02.1f - Problem building LEVER structures\n',cltime(4),cltime(5),cltime(6));
        errStatus = [errStatus Error.PrintException(excp)];
        
        return;
    end
    fprintf('Done\n');
    
    errStatus = '';
end

function segCmd = makeSegCommand(procID, numProc, primaryChannel, metadataFile, cellType, segArg)
    segCmd = 'Segmentor';
    segCmd = [segCmd ' "' num2str(procID) '"'];
    segCmd = [segCmd ' "' num2str(numProc) '"'];
    segCmd = [segCmd ' "' num2str(primaryChannel) '"'];
    segCmd = [segCmd ' "' metadataFile '"'];
    segCmd = [segCmd ' "' cellType '"'];
    
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
