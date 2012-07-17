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

global Figures Colors CONSTANTS GraphEdits ReplayEditActions SegmentationEdits softwareVersion

if(isempty(Figures))
    fprintf('LEVer ver %s\n***DO NOT DISTRIBUTE***\n\n', softwareVersion);
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
if (exist('LEVerSettings.mat','file'))
    load('LEVerSettings.mat');
else
    settings.imagePath = '.\';
    settings.matFilePath = '.\';
end

if (~isfield(settings,'matFilePath'))
    settings.matFilePath = '.\';
end


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

% Clear edits when new data set is opened
SegmentationEdits.newHulls = [];
SegmentationEdits.changedHulls = [];

GraphEdits = [];
ReplayEditActions = [];

answer = questdlg('Run Segmentation and Tracking or Use Existing Data?','Data Source','Segment & Track','Existing','Existing');
switch answer
    case 'Segment & Track'
        Helper.ImageFileDialog();
        save('LEVerSettings.mat','settings');
        
        Load.InitializeConstants();
        Load.AddConstant('version',softwareVersion,1);
        
        type = questdlg('Cell Type:','Cell Type','Adult','Hemato','Adult');
        Load.AddConstant('cellType',type,1);
        errOpen = Segmentation.SegAndTrack();
        if(~errOpen)
            opened = 1;
        else
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
                    errordlg(['Unable to open data: ' exception.msgString]);
                    return
                end
            end
            
            save('LEVerSettings.mat','settings');
            
            CONSTANTS.matFullFile = [settings.matFilePath settings.matFile];
            
            if (~isfield(CONSTANTS,'imageNamePattern') || exist(Helper.GetFullImagePath(1),'file')~=2)
                if (~Helper.ImageFileDialog())
                    return
                end
                save('LEVerSettings.mat','settings');
            end
                
            if(exist('objHulls','var'))
                errordlg('Data too old to run with this version of LEVer');
                return
            end
            
            if (~isfield(CONSTANTS,'cellType'))
                type = questdlg('Cell Type:','Cell Type','Adult','Hemeta','Adult');
                Load.AddConstant('cellType',type,1);
            end
            
            errors = mexIntegrityCheck();
            if ( ~isempty(errors) )
                warndlg('There were database inconsistencies.  LEVer might not behave properly!');
                Dev.PrintIntegrityErrors(errors);
            end
            goodLoad = 1;
        end
        
        Figures.time = 1;
        
        Error.LogAction(['Opened file ' CONSTANTS.matFullFile]);
                
        UI.InitializeFigures();
                
        bUpdated = Load.FixOldFileVersions();

        if ( bUpdated )
            Load.AddConstant('version',softwareVersion,1);
            Helper.SaveLEVerState(CONSTANTS.matFullFile);
        end

        opened = 1;
        
    otherwise
        return
end

% Initialized cached costs here if necessary (placed after fix old file versions for compatibility)
Load.InitializeCachedCosts(0);
end
