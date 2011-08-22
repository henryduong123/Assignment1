% SegAndTrack.m - Spawns segmentation and tracking routines to identify and
% track cells in a sequence of microscope images.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
%     Copyright 2011 Andrew Cohen, Eric Wait and Mark Winter
%
%     This file is part of LEVer - the tool for stem cell lineaging. See
%     https://pantherfile.uwm.edu/cohena/www/LEVer.html for details
% 
%     LEVer is free software: you can redistribute it and/or modify
%     it under the terms of the GNU General Public License as published by
%     the Free Software Foundation, either version 3 of the License, or
%     (at your option) any later version.
% 
%     LEVer is distributed in the hope that it will be useful,
%     but WITHOUT ANY WARRANTY; without even the implied warranty of
%     MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
%     GNU General Public License for more details.
% 
%     You should have received a copy of the GNU General Public License
%     along with LEVer in file "gnu gpl v3.txt".  If not, see 
%     <http://www.gnu.org/licenses/>.
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function status = SegAndTrack()
global CONSTANTS

status = 0;

if (exist('LEVerSettings.mat','file')~=0)
        load('LEVerSettings.mat');
else
    settings.matFilePath = '.\';
end

[settings.matFile,settings.matFilePath,FilterIndex] = uiputfile('.mat','Save edits',...
    [CONSTANTS.imageDatasetName '_LEVer.mat']);

if(~FilterIndex),return,end

status = 1;

save('LEVerSettings.mat','settings');

%% Segmentation
tic

fileList = dir([CONSTANTS.rootImageFolder CONSTANTS.imageDatasetName '*.tif']);
numberOfImages = length(fileList);

cellSegments = [];
numProcessors = getenv('Number_of_processors');
numProcessors = str2double(numProcessors);
if(isempty(numProcessors) || isnan(numProcessors) || numProcessors<4),numProcessors = 4;end

fprintf('Segmenting (using %s processors)...\n',num2str(numProcessors));

if(~isempty(dir('.\segmentationData')))
    system('rmdir /S /Q .\segmentationData');
end

for i=1:numProcessors
    system(['start Segmentor ' num2str(i) ' ' num2str(numProcessors) ' ' ...
        num2str(numberOfImages) ' "' CONSTANTS.rootImageFolder(1:end-1) '" "' CONSTANTS.datasetName '" ' ...
        num2str(CONSTANTS.imageAlpha) ' ' num2str(CONSTANTS.imageSignificantDigits) ' && exit']); 
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

InitializeFigures();

SaveData(1);

LogAction('Segmentation time - Tracking time',tSeg,tTrack);
end