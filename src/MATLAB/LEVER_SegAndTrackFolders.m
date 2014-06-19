 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
%     This file is part of LEVer.exe
%     (C) 2011 Andrew Cohen, Eric Wait and Mark Winter
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% mcc -m LEVER_SegAndTrackFolders.m
function LEVER_SegAndTrackFolders(outputDir, maxProcessors)
global CONSTANTS;

CONSTANTS=[];

softwareVersion = Helper.GetVersion();

cellType = Load.QueryCellType();
Load.AddConstant('cellType',cellType,1);

% Just disable fluorescence for now
Load.AddConstant('rootFluorFolder', '.\', 1);
Load.AddConstant('fluorNamePattern', '.', 1);

directory_name = uigetdir('','Select Root Folder for Seg and Track');
if(~directory_name),return,end

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

dlist=dir(directory_name);

bInvalidName = arrayfun(@(x)(strncmpi(x.name,'.',1) || strncmpi(x.name,'..',2)), dlist);
bValidDir = ~bInvalidName & (vertcat(dlist.isdir) > 0);
dlist = dlist(bValidDir);
for dd=1:length(dlist)
    
    if ( ~(dlist(dd).isdir) )
        continue
    end
 
    fileList = dir(fullfile(directory_name, dlist(dd).name, '*.tif'));
    if ( isempty(fileList) )
        continue
    end
        
    CONSTANTS.rootImageFolder = fullfile(directory_name, dlist(dd).name);
    CONSTANTS.datasetName = [dlist(dd).name '_'];
    CONSTANTS.matFullFile = fullfile(outputDir, [CONSTANTS.datasetName '_LEVer.mat']);
    
    Helper.ParseImageName(fileList(1).name);
    
    if exist(CONSTANTS.matFullFile,'file')
        fprintf('%s - LEVer data already exists.  Skipping\n', CONSTANTS.datasetName);
        continue
    end
    
    Load.InitializeConstants();
    Load.AddConstant('version',softwareVersion,1);
    
    fprintf('seg&track file : %s\n',CONSTANTS.datasetName);
    tic
    CONSTANTS.imageAlpha=1.5;
    %get image significant digits
    firstimfile = fileList(1).name;
    CONSTANTS.imageSignificantDigits = Helper.ParseImageName(firstimfile);
    if ( CONSTANTS.imageSignificantDigits == 0 )
        fprintf('\n**** Image names not formatted correctly for %s.  Skipping\n\n',CONSTANTS.datasetName);
        continue;
    end
    
    if ( ~strcmpi(firstimfile, Helper.GetImageName(1)) )
        fprintf('\n**** Image list does not begin with frame 1 for %s.  Skipping\n\n',CONSTANTS.datasetName);
        continue;
    end
    
    if ( ~bTrialRun )    
        [errStatus tSeg tTrack] = Segmentation.SegAndTrackDataset(CONSTANTS.rootImageFolder, CONSTANTS.datasetName, CONSTANTS.imageAlpha, CONSTANTS.imageSignificantDigits, numProcessors);
        if ( errStatus ~= 0 )
            fprintf('\n\n*** Segmentation/Tracking failed for %s\n\n',CONSTANTS.datasetName);
            continue;
        end

        Helper.SaveLEVerState([CONSTANTS.matFullFile]);

        Error.LogAction('Segmentation time - Tracking time',tSeg,tTrack);
    end
    
    processedDatasets = [processedDatasets; {CONSTANTS.datasetName}];
end %dd

clear global;
end
