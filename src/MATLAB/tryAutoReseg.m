function tryAutoReseg(filename, outFilename)
    rootImageDir = 'B:\Data\NYNSCI\Embryonic\SKG_100312_E12_Ant_vs_Post-0003';
    
    if ( ~exist('outFilename','var') )
        [inPath inName, inExt] = fileparts(filename);
        outFilename = fullfile(inPath,[inName '_autoreseg' inExt]);
    end
    
    load(filename);
    Load.AddConstant('matFullFile', filename);
    
    findImageDir(rootImageDir);
    
    Load.InitializeConstants();
    Load.FixOldFileVersions();
    
    % Check this at the end of load now for new and old data alike
    errors = mexIntegrityCheck();
    if ( ~isempty(errors) )
        Dev.PrintIntegrityErrors(errors);
    end

    % Initialized cached costs here if necessary (placed after fix old file versions for compatibility)
    Load.InitializeCachedCosts(0);
    
    Editor.ReplayableEditAction(@Editor.InitHistory);
    
    runTreeInference();
    runAutoReseg();
end

function runTreeInference()
    global CellFamilies HashedCells
    
    neFam = find(arrayfun(@(x)(~isempty(x.startTime)), CellFamilies));
    runFamilies = neFam(arrayfun(@(x)(x.startTime == 1), CellFamilies(neFam)));
    
    Editor.ReplayableEditAction(@Editor.TreeInference, runFamilies,length(HashedCells));
end

function runAutoReseg()
    global CONSTANTS CellFamilies CellHulls HashedCells Costs
    
    neFam = find(arrayfun(@(x)(~isempty(x.startTime)), CellFamilies));
    runFamilies = neFam(arrayfun(@(x)(x.startTime == 1), CellFamilies(neFam)));
    
    tStart = 2;
    tEnd = length(HashedCells);
    
    bErr = Editor.ReplayableEditAction(@Editor.ResegInitializeAction, runFamilies, 2);
    
    Editor.ReplayableEditAction(@Editor.StartReplayableSubtask, 'AutoResegTask');

%%%%%%%%%
    bFinished = false;

    % Need to worry about deleted hulls?
    costMatrix = Costs;
    bDeleted = ([CellHulls.deleted] > 0);
    costMatrix(bDeleted,:) = 0;
    costMatrix(:,bDeleted) = 0;

    mexDijkstra('initGraph', costMatrix);
    
    
    
    for t=2:tEnd
        xl = [1 CONSTANTS.imageSize(2)];
        yl = [1 CONSTANTS.imageSize(1)];
        
        bErr = Editor.ReplayableEditAction(@Editor.ResegFrameAction, t, tEnd, [xl;yl]);
        
        if ( bErr )
            return;
        end
    end
    
%%%%%%%%%    
    [bErr finishTime] = Editor.ReplayableEditAction(@Editor.ResegFinishAction);
    Editor.ReplayableEditAction(@Editor.StopReplayableSubtask, tEnd-1, 'AutoResegTask');
end

function findImageDir(rootSearchDir)
    global CONSTANTS
    
    fileList = dir(fullfile(rootSearchDir,'*'));
    bInvalidName = arrayfun(@(x)(strncmpi(x.name,'.',1) || strncmpi(x.name,'..',2)), fileList);
    bValidDir = ~bInvalidName & (vertcat(fileList.isdir) > 0);
    
    dirList = fileList(bValidDir);
    
    subDirIdx = find(strcmpi(CONSTANTS.datasetName(1:(end-1)),{dirList.name}));
    if ( isempty(subDirIdx) )
        error('Could not find images in specified directory');
    end
    
    imageDir = fullfile(rootSearchDir,dirList(subDirIdx).name);
    imageList = dir(fullfile(imageDir,'*.tif'));
    if ( isempty(imageList) )
        error('Could not find images in specified directory');
    end
    
    [sigDigits imageDataset] = Helper.ParseImageName(imageList(1).name);
    if ( ~strcmpi(imageDataset,CONSTANTS.datasetName) )
        error('Dataset name mismatch');
    end
    
    Load.AddConstant('rootImageFolder', imageDir, 1);
    Load.AddConstant('imageSignificantDigits', sigDigits, 1);
end
