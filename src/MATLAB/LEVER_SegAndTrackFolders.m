 
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

softwareVersion = Helper.GetVersion();

if (isdeployed())
    Load.SetWorkingDir();
end

cellType = Load.QueryCellType();
Load.AddConstant('cellType',cellType,1);

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

processedDatasets = {};

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

dirList = dir(directory_name);

bInvalidName = arrayfun(@(x)(strncmpi(x.name,'.',1) || strncmpi(x.name,'..',2)), dirList);
bValidDir = ~bInvalidName & (vertcat(dirList.isdir) > 0);
dirList = dirList(bValidDir);

for dirIdx=1:length(dirList)
    if ( ~(dirList(dirIdx).isdir) )
        continue
    end
    
    validStartFilename = getValidStartFileName(fullfile(directory_name, dirList(dirIdx).name));
    if ( isempty(validStartFilename) )
        fprintf('\n**** Image list does not begin with frame 1 for %s.  Skipping\n\n', directory_name);
        continue;
    end
    
    [datasetName namePattern] = Helper.ParseImageName(validStartFilename);
    if ( isempty(datasetName) )
        fprintf('\n**** Image names not formatted correctly for %s.  Skipping\n\n', directory_name);
        continue;
    end
 
    CONSTANTS.rootImageFolder = fullfile(directory_name, dirList(dirIdx).name);
    CONSTANTS.datasetName = datasetName;
    CONSTANTS.imageNamePattern = namePattern;
    CONSTANTS.matFullFile = fullfile(outputDir, [CONSTANTS.datasetName '_LEVer.mat']);
    
    if ( exist(CONSTANTS.matFullFile,'file') )
        fprintf('%s - LEVer data already exists.  Skipping\n', CONSTANTS.datasetName);
        continue
    end
    
    fileList = dir(fullfile(directory_name, dirList(dirIdx).name, '*.tif'));
    if ( isempty(fileList) )
        continue
    end

    Load.AddConstant('version',softwareVersion,1);
    
    fprintf('Segment & track file : %s\n', CONSTANTS.datasetName);
    
    tic
    Load.InitializeConstants();

    if ( ~bTrialRun )
        segArgs = Helper.GetCellTypeSegParams(CONSTANTS.cellType);
        [errStatus tSeg tTrack] = Segmentation.SegAndTrackDataset(CONSTANTS.rootImageFolder, CONSTANTS.datasetName, CONSTANTS.imageNamePattern, numProcessors, segArgs);
        if ( ~isempty(errStatus) )
            fprintf('\n\n*** Segmentation/Tracking failed for %s\n\n', CONSTANTS.datasetName);
            
            errFilename = fullfile(outputDir, [CONSTANTS.datasetName '_segtrack_err.log']);
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
    
    processedDatasets = [processedDatasets; {CONSTANTS.datasetName}];
end %dd

clear global;
end

% This function tries to quickly find one or more files that qualify as an
% initial image frame for parsing dataset names, etc. Returns the first
% file name found
function filename = getValidStartFileName(chkPath)
    filename = '';
    
    flist = [];
    chkDigits = 7:-1:2;
    for i=1:length(chkDigits)
        digitStr = ['%0' num2str(chkDigits(i)) 'd'];
        flist = dir(fullfile(chkPath,['*_t' num2str(1,digitStr) '*.tif']));
        if ( ~isempty(flist) )
            break;
        end
    end
    
    if ( isempty(flist) )
        return;
    end
    
    filename = flist(1).name;
end
