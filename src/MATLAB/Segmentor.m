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

function [hulls frameTimes] = Segmentor(varargin)

hulls = [];
frameTimes = [];

supportedCellTypes = Load.GetSupportedCellTypes();
[procArgs,segArgs] = setSegArgs(supportedCellTypes, varargin);
if ( isempty(procArgs) )
    return;
end

if ( isempty(procArgs.primaryChannel) )
	procArgs.primaryChannel = 1;
end

% Use the supported type structure to find segmentation routine
typeIdx = findSupportedTypeIdx(procArgs.cellType, supportedCellTypes);
funcName = char(supportedCellTypes(typeIdx).segRoutine.func);
funcPath = which(funcName);

if ( ~isempty(funcPath) )
    segFunc = supportedCellTypes(typeIdx).segRoutine.func;
else
    fprintf(['WARNING: Could not find ' funcName '() using default Segmentation.FrameSegmentor() routine\n']);
    segFunc = @Segmentation.FrameSegmentor;
end

segParams = struct2cell(segArgs);

try 
    fprintf(1,'%s\n',procArgs.imagePath);
    fprintf(1,'%s\n',procArgs.imagePattern);
    
    Load.AddConstant('rootImageFolder', procArgs.imagePath, 1);
    Load.AddConstant('imageNamePattern', procArgs.imagePattern, 1);
    Load.AddConstant('numChannels', procArgs.numChannels, 1);
    Load.AddConstant('numFrames', procArgs.numFrames, 1);
    Load.AddConstant('primaryChannel', procArgs.primaryChannel, 1);
    
    tStart = procArgs.procID;
    tEnd = procArgs.numFrames;
    tStep = procArgs.numProcesses;
    primaryChan = procArgs.primaryChannel;
    
    numImages = floor(tEnd/tStep);

    for t = tStart:tStep:tEnd
        fprintf('%d%%...', round(100 * floor(t/tStep) / numImages));
        
        chanImSet = Helper.LoadIntensityImageSet(t);
        if ( isempty(chanImSet) )
            continue;
        end
        
        frameHulls = segFunc(chanImSet, primaryChan, t, segParams{:});
        
        for i=1:length(frameHulls)
            if ( ~isfield(frameHulls(i),'tag') || isempty(frameHulls(i).tag) )
                frameHulls(i).tag = char(segFunc);
            else
                frameHulls(i).tag = [char(segFunc) ':' frameHulls(i).tag];
            end
        end
        
        hulls = [hulls frameHulls];
        frameTimes = [frameTimes t];
    end
    
catch excp
    cltime = clock();
    errFilename = ['.\segmentationData\err_' num2str(procArgs.procID) '.log'];
    fid = fopen(errFilename, 'w');
    if ( ~exist('t', 'var') )
        fprintf(fid, '%02d:%02d:%02.1f - Error in segmentor\n',cltime(4),cltime(5),cltime(6));
    else
        fprintf(fid, '%02d:%02d:%02.1f - Error in segmenting frame %d \n',cltime(4),cltime(5),cltime(6), t);
    end
    excpMessage = Error.PrintException(excp);
    fprintf(fid, '%s', excpMessage);
    fclose(fid);
    return;
end

fileName = fullfile('segmentationData',['objs_' num2str(tStart) '.mat']);
save(fileName,'hulls','frameTimes');

% Write this file to indicate that the segmentaiton data is actually fully saved
fSempahore = fopen(fullfile('segmentationData',['done_' num2str(tStart) '.txt']), 'w');
fclose(fSempahore);

fprintf('\tDone\n');
end

function [procArgs segArgs] = setSegArgs(supportedCellTypes, argCell)
    procArgs = struct('procID',{1}, 'numProcesses',{1}, 'numChannels',{0}, 'numFrames',{0}, 'cellType',{''}, 'primaryChannel',{[]}, 'imagePath',{''}, 'imagePattern',{''});
    
    procArgFields = fieldnames(procArgs);
    procArgTypes = cellfun(@(x)(class(x)), struct2cell(procArgs), 'UniformOutput',0);
    
    segArgs = [];
    
    procArgs.procID = 1;
    if ( ~isempty(argCell) )
       procArgs.procID = convertArg(argCell{1}, procArgTypes{1});
    end
    errFilename = ['.\segmentationData\err_' num2str(procArgs.procID) '.log'];
    
    if ( length(argCell) < length(procArgFields) )
        cltime = clock();
        
        fid = fopen(errFilename, 'w');
        fprintf(fid, '%02d:%02d:%02.1f - Problem segmenting frame \n',cltime(4),cltime(5),cltime(6));
        fprintf(fid, '  Too few input arguments expected at least %d: %d missing\n', length(argFields), (length(argFields) - length(argCell)));
        
        printArgs(fid, argCell, procArgFields);

        fclose(fid);
        
        procArgs = [];
        return;
    end
    
    procArgs = makeArgStruct(argCell, procArgFields, procArgTypes);
    
    % Use cell type to figure out what segmentation parameters are
    % available, and what algorithm to use.
    typeIdx = findSupportedTypeIdx(procArgs.cellType, supportedCellTypes);
    
    segArgCell = argCell(length(procArgFields)+1:end);
    segArgFields = {supportedCellTypes(typeIdx).segRoutine.params.name};
    segArgTypes = cell(1,length(segArgFields));
    [segArgTypes{:}] = deal('double');
    
    if ( (length(segArgCell)) ~= length(segArgFields) )
        cltime = clock();
        
        fid = fopen(errFilename, 'w');
        fprintf(fid, '%02d:%02d:%02.1f - Problem segmenting frame \n',cltime(4),cltime(5),cltime(6));
        if ( length(segArgCell) > length(segArgFields) )
            fprintf(fid, '  Too many input arguments expected %d: %d extra\n', length(segArgFields), (length(segArgCell)-length(segArgFields)));
        else
            fprintf(fid, '  Too few input arguments expected %d: %d missing\n', length(segArgFields), (length(segArgFields) - length(segArgCell)));
        end
        
        printArgs(fid, segArgCell, [procArgFields segArgFields]);

        fclose(fid);
        
        procArgs = [];
        return;
    end
    
    segArgs = makeArgStruct(segArgCell, segArgFields, segArgTypes);
end

function typeIdx = findSupportedTypeIdx(cellType, supportedTypes)
    typeIdx = find(strcmpi(cellType, {supportedTypes.name}),1,'first');
    
    % Try default cell type if we don't have current type in supported list.
    if ( isempty(typeIdx) )
        fprintf(['WARNING: Unsupported cell type: ' cellType ' using default "Embryonic" cell type instead\n']);
        
        cellType = 'Embryonic';
        typeIdx = find(strcmpi(cellType, {supportedTypes.name}),1,'first');
    end
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
        outArg = cast(str2num(inArg), toType);
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

