 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
%     This file is part of LEVer.exe
%     (C) 2011 Andrew Cohen, Eric Wait and Mark Winter
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% mcc -m LEVER_SegAndTrackFolders.m
function LEVER_SegAndTrackFolders(outputDir, maxProcessors)
global CONSTANTS softwareVersion;

CONSTANTS=[];

softwareVersion = '6.1 Adult';

Load.InitializeConstants();
Load.UpdateFileVersionString(softwareVersion);

directory_name = uigetdir('','Select Root Folder for Seg and Track');
if(~directory_name),return,end

if ( ~exist('outputDir','var') )
    outputDir = directory_name;
end

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
for dd=1:length(dlist)
    
    if ( ~(dlist(dd).isdir) )
        continue
    end
 
    fileList = dir(fullfile([directory_name filesep dlist(dd).name], '*.tif'));
    numberOfImages = length(fileList);

    if ( 0 == numberOfImages )
        continue
    end
        
    CONSTANTS.rootImageFolder = [directory_name filesep dlist(dd).name];
    CONSTANTS.datasetName = dlist(dd).name;
    CONSTANTS.matFullFile = fullfile(outputDir, [CONSTANTS.datasetName '_LEVer.mat']);
    
    if exist(CONSTANTS.matFullFile,'file')
        continue
    end
    
    fprintf('seg&track file : %s\n',CONSTANTS.datasetName);
    tic
    CONSTANTS.imageAlpha=1.5;
    %get image significant digits
    firstimfile = fileList(1).name;
    CONSTANTS.imageSignificantDigits = GetImageSigDigits(firstimfile);
    if ( CONSTANTS.imageSignificantDigits == 0 )
        fprintf('\n**** Image names not formatted correctly for %s.  Skipping\n',CONSTANTS.datasetName);
        continue;
    end
    
    [errStatus tSeg tTrack] = Segmentation.SegAndTrackDataset(CONSTANTS.rootImageFolder, CONSTANTS.datasetName, CONSTANTS.imageAlpha, CONSTANTS.imageSignificantDigits, numProcessors);
    if ( errStatus ~= 0 )
        fprintf('\n\n*** Segmentation/Tracking failed for %s\n\n',CONSTANTS.datasetName);
        continue;
    end
    
    UI.SaveData(1);

    Error.LogAction('Segmentation time - Tracking time',tSeg,tTrack);
end %dd

clear global;
end