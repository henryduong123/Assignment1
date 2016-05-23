% OpenData.m - 
% Opens the data file either from a previous state of LEVer or from tracking
% results.  If the latter, the data will be converted to LEVer's data scheme
% and save out to a new file.

% ChangeLog:
% EW - Rewrite 
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

function opened = OpenData()
global Figures Colors CONSTANTS

softwareVersion = Dev.GetVersion();
if(isempty(Figures))
    fprintf('%s\n***DO NOT DISTRIBUTE***\n\n', softwareVersion);
end

if(exist('ColorScheme.mat','file'))
    load 'ColorScheme.mat';
    if(exist('colors','var'))
        %legacy fix
        Colors = colors;
        save('ColorScheme','Colors');
    end
else
    Colors = Load.CreateColors();
    save('ColorScheme','Colors');
end
    
%Settings is used for open file dialog to remember last location
settings = Load.ReadSettings();

goodLoad = 0;
opened = 0;

if(~isempty(Figures))
    if(strcmp(get(Figures.cells.menuHandles.saveMenu,'Enable'),'on'))
        choice = questdlg('Save current edits before opening new data?','Closing','Yes','No','Cancel','Cancel');
        switch choice
            case 'Yes'
                UI.SaveData(0);
            case 'Cancel'
                return
            case 'No'
                set(Figures.cells.menuHandles.saveMenu,'Enable','off');
            otherwise
                return
        end
        try
            %clear out globals so they can rewriten
            if(ishandle(Figures.cells.handle))
                close Figures.cells.handle
                wasOpened = 1;
            end
        catch exception
        end
    end
end

oldCONSTANTS = CONSTANTS;

Helper.ClearAllGlobals();

answer = questdlg('Run Segmentation and Tracking or Use Existing Data?','Data Source','Segment & Track','Existing','Existing');
switch answer
    case 'Segment & Track'
        if (~Helper.ImageFileDialog())
            return;
        end
        Load.ReadSettings();
        
        Load.AddConstant('version',softwareVersion,1);
        Load.AddConstant('cellType', [], 1);
        
        UI.SegPreview();
        if ( isempty(CONSTANTS.cellType) )
            return;
        end
        
        Load.InitializeConstants();
        
        errOpen = Segmentation.SegAndTrack();
        if ( isempty(errOpen) )
            opened = 1;
        else
            CONSTANTS = oldCONSTANTS;
            return
        end
    case 'Existing'
        while(~goodLoad)
            fprintf('Select .mat data file...\n');
            [settings.matFile,settings.matFilePath,filterIndexMatFile] = uigetfile([settings.matFilePath '*.mat'],...
                'Open Data',[settings.matFilePath settings.matFile]);
            
            if (filterIndexMatFile==0)
                return
            else
                fprintf('Opening file...');
				
                try
                    load([settings.matFilePath settings.matFile]);
                    fprintf('\nFile open.\n\n');
                catch exception
                    errordlg(['Unable to open data: ' exception.message]);
                    return
                end
            end
            
            Load.SaveSettings(settings);
            Load.AddConstant('matFullFile', [settings.matFilePath settings.matFile], 1);
            
            % Update imageData.DatasetName early enough to check for
            % image/data match.
            if ( isfield(CONSTANTS,'datasetName') )
                oldName = CONSTANTS.datasetName;
                if ( oldName(end) == '_' )
                    oldName = oldName(1:end-1);
                end
                
                Load.AddConstant('imageData.DatasetName',oldName,true);
            end
            
            imageData = MicroscopeData.ReadMetadata(fullfile(CONSTANTS.rootImageFolder, [Metadata.GetDatasetName() '.json']), false);
            if ( isempty(imageData) )
                if ( exist(CONSTANTS.rootImageFolder,'dir') )
                    error('No metadata found in image directory, currently unsupported!');
                elseif (~Helper.ImageFileDialog())
                    CONSTANTS = oldCONSTANTS;
                    return
                end
            else
                Metadata.SetMetadata(imageData);
            end
            
            if(exist('objHulls','var'))
                errordlg('Data too old to run with this version of LEVer');
                CONSTANTS = oldCONSTANTS;
                return
            end
            
            goodLoad = 1;
        end
        
        Load.InitializeConstants();
        
        bUpdated = Load.FixOldFileVersions();
        
        Error.LogAction(['Opened file ' CONSTANTS.matFullFile]);

        if ( bUpdated )
            Load.AddConstant('version',softwareVersion,1);
            ovwAns = questdlg('Old file format detected! Update required. Would you like to save the updated file to a new location?', ... 
                                'Verision Update', ... 
                                'Save As...','Overwrite','Overwrite'); 
            
            bValidAns = false;
            % Handle response 
            switch ovwAns 
                case 'Save As...' 
                    bValidAns = UI.SaveDataAs(true);
                case 'Overwrite'
                    bValidAns = true;
                    Helper.SaveLEVerState(CONSTANTS.matFullFile);
            end
            
            if ( ~bValidAns )
                warning('Proceeding without updating file, be sure to save before exiting LEVer!');
            end
        end
        
         UI.InitializeFigures();
         opened = 1;
        
    otherwise
        return
end

% Check this at the end of load now for new and old data alike
errors = mexIntegrityCheck();
if ( ~isempty(errors) )
    warndlg('There were database inconsistencies.  LEVer might not behave properly!');
    Dev.PrintIntegrityErrors(errors);
end

% Initialized cached costs here if necessary (placed after fix old file versions for compatibility)
Load.InitializeCachedCosts(0);
end
