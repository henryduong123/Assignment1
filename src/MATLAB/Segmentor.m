% Segmentor.m - Cell image segmentation algorithm.
% Segmentor is to be run as a seperate compiled function for parallel
% processing.  It will process tLength-tStart amount of images.  Call this
% function for the number of processors on the machine.

% mcc -o Segmentor -m Segmentor.m

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

function [objs features levels] = Segmentor(varargin)

objs=[];
features = [];
levels = struct('haloLevel',{}, 'igLevel',{});

argStruct = setSegArgs(varargin);
if ( isempty(argStruct) )
    return;
end

if ( exist(fullfile('+Segmentation',[argStruct.cellType 'FrameSegmentor']), 'file') )
    segFunc = str2func(['Segmentation.' argStruct.cellType 'FrameSegmentor']);
else
    fprintf(['WARNING: Could not find Segmentation.' argStruct.cellType 'FrameSegmentor() using default segmentation routine\n']);
    segFunc = @Segmentation.FrameSegmentor;
end

try 
    fprintf(1,'%s\n',argStruct.rootImageFolder);
    fprintf(1,'%s\n',argStruct.imageNamePattern);
    
    Load.AddConstant('rootImageFolder', argStruct.rootImageFolder, 1);
    Load.AddConstant('imageNamePattern', argStruct.imageNamePattern, 1);
    Load.AddConstant('rootFluorFolder', [argStruct.rootFluorFolder '\'], 1);
    Load.AddConstant('fluorNamePattern', argStruct.fluorNamePattern, 1);
    
    tStart = argStruct.tStart;
    tEnd = argStruct.tEnd;
    tStep = argStruct.tStep;
    
    numImages = tEnd/tStep;

    for t = tStart:tStep:tEnd
        fname=Helper.GetFullImagePath(t);
        if(isempty(dir(fname)))
            continue;
        end

        fprintf('%d%%...',floor(floor(t/tStep)/numImages*100));

        im = Helper.LoadIntensityImage(fname);

        [frmObjs frmFeatures frmLevels] = segFunc(im, t, argStruct.imageAlpha);
        objs = [objs frmObjs];
        features = [features frmFeatures];
        levels = [levels frmLevels];
    end
    
catch excp
    cltime = clock();
    errFilename = ['.\segmentationData\err_' num2str(tStart) '.log'];
    fid = fopen(errFilename, 'w');
    fprintf(fid, '%02d:%02d:%02.1f - Problem segmenting frame \n',cltime(4),cltime(5),cltime(6));%, t);
    Error.PrintException(fid, excp);
    fclose(fid);
    return;
end

fileName = ['.\segmentationData\objs_' num2str(tStart) '.mat'];
save(fileName,'objs','features','levels');

fSempahore = fopen(['.\segmentationData\done_' num2str(tStart) '.txt'], 'w');
fclose(fSempahore);

fprintf('\tDone\n');
end

function argStruct = setSegArgs(argCell)
    argStruct = [];
    
    % If a field is added or modified make sure to add corresponding type.
    argFields = {'tStart','tStep','tEnd','cellType','imageAlpha','rootImageFolder','imageNamePattern','rootFluorFolder','fluorNamePattern'};
    argTypes = {'double','double','double','char','double','char','char','char','char'};
    
    procID = 1;
    if ( ~isempty(argCell) )
        procID = convertArg(argCell{1}, argTypes{1});
    end
    errFilename = ['.\segmentationData\err_' num2str(procID) '.log'];
    
    if ( length(argCell) ~= length(argFields) )
        cltime = clock();
        
        fid = fopen(errFilename, 'w');
        fprintf(fid, '%02d:%02d:%02.1f - Problem segmenting frame \n',cltime(4),cltime(5),cltime(6));%, t);
        
        if ( length(argCell) > length(argFields) )
            fprintf(fid, '  Too many input arguments expected %d: %d extra\n', length(argFields), (length(argCell)-length(argFields)));
        else
            fprintf(fid, '  Too few input arguments expected %d: %d missing\n', length(argFields), (length(argFields) - length(argCell)));
        end
        
        printArgs(fid, argCell, argFields);

        fclose(fid);
        return;
    end
    
    argStruct = makeArgStruct(argCell, argFields, argTypes);
end

function argStruct = makeArgStruct(argCell, argFields, argTypes)
    argStruct = struct();
    for i=1:length(argFields);
        argStruct.(argFields{i}) = convertArg(argCell{i}, argTypes{i});
    end
end

function outArg = convertArg(inArg, toType)
    if ( strcmpi(toType,'char') )
        outArg = num2str(inArg);
    elseif ( ischar(inArg) )
        outArg = cast(str2double(inArg), toType);
    else
        outArg = cast(inArg, toType);
    end
end

function printArgs(fid, argCell, argFields)
    for i=1:length(argFields)
        curArg = '[]';
        if ( i <= length(argCell) )
            curArg = num2str(argCell{i});
        end
        
        fprintf(fid, '    %d: %s = %s\n', i, argFields{i}, curArg);
    end
    
    for i=(length(argFields)+1):length(argCell)
        curArg = num2str(argCell{i});
        fprintf(fid, '    %d: [] = %s\n', i, curArg);
    end
end

