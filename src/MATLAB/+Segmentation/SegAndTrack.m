% SegAndTrack.m - Spawns segmentation and tracking routines to identify and
% track cells in a sequence of microscope images.

% ChangeLog
% EW - rewrite
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

function errStatus = SegAndTrack()
    global CONSTANTS CellPhenotypes

    % Modified 
    errStatus = 'Cancel';
    
    settings = Load.ReadSettings();

    [settings.matFile,settings.matFilePath,FilterIndex] = uiputfile('.mat','Save edits',...
        [CONSTANTS.datasetName '_LEVer.mat']);

    if(~FilterIndex)
        return;
    end

    % 
    Load.SaveSettings(settings);
    Load.AddConstant('matFullFile',[settings.matFilePath settings.matFile],1);
    
    numProcessors = getenv('Number_of_processors');
    numProcessors = str2double(numProcessors);
    if(isempty(numProcessors) || isnan(numProcessors) || numProcessors < 4)
        numProcessors = 4;
    end
    
    % TODO: Rewrite for more extensible segmentation/tracking interface:
    % Check for <celltype>Seg.exe, if it exists it is assumed to be a
    % full-movie segmentation which handles threading internally
    % (see e.g. HematoSeg.exe)
    
    errStatus = '';
    segArgs = Helper.GetCellTypeSegParams(CONSTANTS.cellType);
    [errStatus tSeg tTrack] = Segmentation.SegAndTrackDataset(CONSTANTS.rootImageFolder, CONSTANTS.datasetName, CONSTANTS.imageNamePattern, numProcessors, segArgs);
    
    if ( ~isempty(errStatus) )
        errFilename = [CONSTANTS.datasetName '_segtrack_err.log'];
        
        fprintf('ERROR: Segmentation/Tracking did not complete successfully.\n');
        fprintf('       See %s for more details.\n',errFilename);
        
        fid = fopen(errFilename, 'wt');
        fprintf(fid, '%s', errStatus);
        fclose(fid);
        
        return
    end
    
    % Initialize cell phenotype structure in all cases.
    CellPhenotypes = struct('descriptions', {{'died' 'ambiguous' 'off screen'}}, 'hullPhenoSet', {zeros(2,0)}, 'colors',{[0 0 0;.549 .28235 .6235;0 1 1]});
    
    UI.InitializeFigures();
    
    UI.SaveData(1);
    
    % Adds the special origin action, to indicate that this is initial
    % segmentation data from which edit actions are built.
    Editor.ReplayableEditAction(@Editor.OriginAction, 1);
    
    Error.LogAction('Segmentation time - Tracking time',tSeg,tTrack);
end
