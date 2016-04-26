 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
%     This file is part of LEVer.exe
%     (C) 2011 Andrew Cohen, Eric Wait and Mark Winter
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% mcc -m LEVER_SegAndTrackFolders.m
function LEVER_SegAndTrackFolders(outputDir, maxProcessors)
global CONSTANTS CellPhenotypes

CONSTANTS=[];

softwareVersion = Dev.GetVersion();

if (isdeployed())
    Load.SetWorkingDir();
end

directory_name = uigetdir('','Select Root Folder for Seg and Track');
if ( ~directory_name ),return,end

if ( ~exist('outputDir','var') )
    outputDir = directory_name;
end

% Trial run command
bTrialRun = 0;
if ( strcmpi(outputDir(1:2),'-T') )
    outputDir = outputDir(3:end);
    if ( isempty(outputDir) )
        outputDir = directory_name;
    end
    bTrialRun = 1;
end

%% Get a list of valid subdirectories
dirList = dir(directory_name);

bInvalidName = arrayfun(@(x)(strncmpi(x.name,'.',1) || strncmpi(x.name,'..',2)), dirList);
bValidDir = ~bInvalidName & (vertcat(dirList.isdir) > 0);
dirList = dirList(bValidDir);

validDirs = {};
for dirIdx=1:length(dirList)
    if ( ~(dirList(dirIdx).isdir) )
        continue
    end
    
    imageData = MicroscopeData.ReadMetadata([fullfile(directory_name,dirList(dirIdx).name) '\'],false);
    if ( isempty(imageData) )
        continue;
    end
    
    validDirs = [validDirs; dirList(dirIdx).name];
end

%% Use previewer on first valid directory to get cell type and segmentation parameters
Load.AddConstant('version',softwareVersion,1);
Load.AddConstant('cellType', [], 1);

[imageData,imagePath] = MicroscopeData.ReadMetadata([fullfile(directory_name, validDirs{1}) '\']);
Metadata.SetMetadata(imageData);

Load.AddConstant('rootImageFolder', imagePath, 1);
Load.AddConstant('matFullFile', fullfile(outputDir, Metadata.GetDatasetName()),1);

UI.SegPreview();
if ( isempty(CONSTANTS.cellType) )
    return;
end

cellType = CONSTANTS.cellType;

%% Use total number of processors or max from command-line
numProcessors = getenv('Number_of_processors');
numProcessors = str2double(numProcessors);
if(isempty(numProcessors) || isnan(numProcessors) || numProcessors < 4)
    numProcessors = 4;
end

if ( exist('maxProcessors','var') )
    if ( ischar(maxProcessors) )
        maxProcessors = round(max(str2double(maxProcessors), 1));
    end
    numProcessors = min(maxProcessors, numProcessors);
end

%% Run segmentation for all valid directories
processedDatasets = {};
for dirIdx=1:length(validDirs)
    [imageData,imagePath] = MicroscopeData.ReadMetadata([fullfile(directory_name, validDirs{dirIdx}) '\']);
    Metadata.SetMetadata(imageData);

    Load.AddConstant('rootImageFolder', imagePath, 1);
    Load.AddConstant('matFullFile', fullfile(outputDir, [Metadata.GetDatasetName() '_LEVer.mat']),1);
    
    if ( exist(CONSTANTS.matFullFile,'file') )
        fprintf('%s - LEVer data already exists.  Skipping\n', Metadata.GetDatasetName());
        continue
    end

    Load.AddConstant('version',softwareVersion,1);
    
    %% Segment and track folder
    fprintf('Segment & track file : %s\n', Metadata.GetDatasetName());
    tic

    if ( ~bTrialRun )
        Load.InitializeConstants();
        
        segArgs = Segmentation.GetCellTypeParams();
        [errStatus tSeg tTrack] = Segmentation.SegAndTrackDataset(numProcessors, segArgs);
        if ( ~isempty(errStatus) )
            fprintf('\n\n*** Segmentation/Tracking failed for %s\n\n', Metadata.GetDatasetName());
            
            errFilename = fullfile(outputDir, [Metadata.GetDatasetName() '_segtrack_err.log']);
            fid = fopen(errFilename, 'wt');
            fprintf(fid, '%s', errStatus);
            fclose(fid);
            
            continue;
        end
        
        % Initialize cell phenotype structure in all cases.
        CellPhenotypes = struct('descriptions', {{'died' 'ambiguous' 'off screen'}}, 'hullPhenoSet', {zeros(2,0)}, 'colors',{[0 0 0;.549 .28235 .6235;0 1 1]});
        
        % Adds the special origin action, to indicate that this is initial
        % segmentation data from which edit actions are built.
        Editor.ReplayableEditAction(@Editor.OriginAction, 1);
        
        Helper.SaveLEVerState([CONSTANTS.matFullFile]);
        Error.LogAction('Segmentation time - Tracking time',tSeg,tTrack);
    end
    
    processedDatasets = [processedDatasets; {Metadata.GetDatasetName()}];
end %dd

clear global;
end
