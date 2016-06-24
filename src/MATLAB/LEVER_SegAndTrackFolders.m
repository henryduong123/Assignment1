 
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

if ( ~exist('outputDir','var') )
    outputDir = '';
end

% Trial run command
bTrialRun = false;
if ( strncmpi(outputDir,'-T',2) )
    outputDir = outputDir(3:end);
    bTrialRun = true;
end

softwareVersion = Dev.GetVersion();

if (isdeployed())
    Load.SetWorkingDir();
end

directory_name = uigetdir('','Select Root Folder for Seg and Track');
if ( ~directory_name ),return,end

% Get initial cell segmentation parameters
Load.AddConstant('cellType', [], 1);

hDlg = UI.SegPropDialog();
uiwait(hDlg);

if ( isempty(CONSTANTS.cellType) )
    return;
end

%% Run export of subdirectories if necessary.
exportRoot = Load.FolderExport(directory_name);
if ( isempty(exportRoot) )
    return;
end

if ( isempty(outputDir) )
    outputDir = exportRoot;
end

%% Find valid images in exported folder.
[chkPaths,invalidFile] = Load.CheckFolderExport(exportRoot);
validJSON = chkPaths(~invalidFile);

if ( isempty(validJSON) )
    warning(['No valid data found at: ' exportRoot]);
    return;
end

%% Use previewer on first valid directory to get cell type and segmentation parameters
Load.AddConstant('version',softwareVersion,1);

[imageData,imagePath] = MicroscopeData.ReadMetadataFile(fullfile(exportRoot,validJSON{1}));
Metadata.SetMetadata(imageData);

Load.AddConstant('rootImageFolder', imagePath, 1);
Load.AddConstant('matFullFile', fullfile(outputDir, Metadata.GetDatasetName()),1);

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
for dirIdx=1:length(validJSON)
    subDir = fileparts(validJSON{dirIdx});
    dataDir = fileparts(subDir);
    
    [imageData,imagePath] = MicroscopeData.ReadMetadataFile(fullfile(exportRoot,validJSON{dirIdx}));
    Metadata.SetMetadata(imageData);

    Load.AddConstant('rootImageFolder', imagePath, 1);
    Load.AddConstant('matFullFile', fullfile(outputDir,dataDir, [Metadata.GetDatasetName() '_LEVer.mat']),1);
    
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
