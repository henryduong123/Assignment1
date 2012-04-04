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

function [objs features levels] = Segmentor(tStart,tStep,tEnd,rootImageFolder,datasetName,imageAlpha,imageSignificantDigits)
    
objs=[];
features = [];
levels = struct('haloLevel',{}, 'igLevel',{});

% try
    if(isempty(dir('.\segmentationData')))
        system('mkdir .\segmentationData');
    end

    if(ischar(tStart)),tStart = str2double(tStart);end
    if(ischar(tStep)),tStep = str2double(tStep);end
    if(ischar(tEnd)),tEnd = str2double(tEnd);end
    if(ischar(imageAlpha)),imageAlpha = str2double(imageAlpha);end
    if(ischar(imageSignificantDigits)),imageSignificantDigits = str2double(imageSignificantDigits);end

    numImages = tEnd/tStep;

    for t = tStart:tStep:tEnd
        frameT = SignificantDigits(t,imageSignificantDigits);
        fname=fullfile(rootImageFolder, [datasetName '_t' frameT '.TIF']);
        if(isempty(dir(fname)))
            continue;
        end

        fprintf('%d%%...',floor(floor(t/tStep)/numImages*100));

        [im map]=imread(fname);

        [frmObjs frmFeatures frmLevels] = FrameSegmentor(im, t, imageAlpha);
        objs = [objs frmObjs];
        features = [features frmFeatures];
        levels = [levels frmLevels];
    end
    
% catch excp
%     cltime = clock();
%     errFilename = ['.\segmentationData\err_' num2str(tStart) '.log'];
%     fid = fopen(errFilename, 'w');
%     fprintf(fid, '%02d:%02d:%02.1f - Problem segmenting frame %d\n',cltime(4),cltime(5),cltime(6), t);
%     printExcp(fid, excp);
%     fclose(fid);
%     return;
% end

fileName = ['.\segmentationData\objs_' num2str(tStart) '.mat'];
save(fileName,'objs','features','levels');

fprintf('\tDone\n');
end

function printExcp(fid, excp, prefixstr)
    if ( ~exist('prefixstr','var') )
        prefixstr = '  ';
    end
    
    fprintf(fid,'%s',prefixstr);
    fprintf(fid, 'stacktrace: \n');
    numspaces = 5;
    stacklevel = 1;
    for i=length(excp.stack):-1:1
        fprintf(fid,'%s',prefixstr);
        for j=1:numspaces
            fprintf(fid,' ');
        end
        
        fprintf(fid,'%d.',stacklevel);
        for j=1:stacklevel
            fprintf(fid,' ');
        end
        
        [mfdir mfile mfext] = fileparts(excp.stack(i).file);
        
        fprintf(fid, '%s%s: %s(): %d\n', mfile, mfext, excp.stack(i).name, excp.stack(i).line);
        
        stacklevel = stacklevel + 1;
    end
    fprintf(fid,'%s',prefixstr);
    fprintf(fid, 'message: %s\n', excp.message);
end
