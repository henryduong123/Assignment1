% CompileLEVer.m - Script to build LEVer and its dependencies

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

function CompileLEVer()
    totalTime = tic();

    % Try to set up git for the build, give a warning about checking the
    % fallback file if we can't find git.
    bFoundGit = Dev.SetupGit();
    if ( ~bFoundGit )
        questionStr = sprintf('%s\n%s','Cannot find git you should verify the fallback file version info before building.','Are you sure you wish to continue with the build?');
        result = questdlg(questionStr,'Build Warning','Yes','No','No');
        if ( strcmpi(result,'No') )
            return;
        end
    end

    % Give a messagebox warning if there are uncommitted changes.
    % Note: even committed changes may not have been pushed to server.
    [status,result] = system('git status --porcelain');
    if ( status == 0 && (length(result) > 1) )
        questionStr = sprintf('%s\n%s','There are uncommitted changes in your working directory','Are you sure you wish to continue with the build?');
        result = questdlg(questionStr,'Build Warning','Yes','No','No');
        if ( strcmpi(result,'No') )
            return;
        end
    end

    Dev.MakeVersion();

    [vsStruct comparch] = setupCompileTools();
    
    bindir = '..\..\bin';
    if ( strcmpi(comparch,'win64') )
        bindir = '..\..\bin64';
    end

    if ( ~exist(bindir,'dir') )
        mkdir(bindir);
    end
    
    compileMEX('mexMAT', vsStruct);
    compileMEX('mexDijkstra', vsStruct);
    compileMEX('mexGraph', vsStruct);
    compileMEX('mexIntegrityCheck', vsStruct);
    compileMEX('mexHashData', vsStruct);
    compileMEX('mexCCDistance', vsStruct);
    
    compileEXE('MTC', vsStruct, bindir);
    compileEXE('HematoSeg', vsStruct, bindir);
    compileEXE('GrayScaleCrop', vsStruct, bindir);

    [toolboxStruct externalStruct] = Dev.GetExternalDependencies();
    if ( ~isempty(externalStruct.deps) )
        fprintf('ERROR: Some local functions have external dependencies\n');
        for i=1:length(externalStruct.deps)
            fprintf('[%d]  %s\n', i, externalStruct.deps{i});
            for j=1:length(externalStruct.funcs{i})
                if ( ~isempty(externalStruct.callers{i}{j}) )
                    for k=1:length(externalStruct.callers{i}{j})
                        localName = Dev.GetLocalName(externalStruct.callers{i}{j}{k});
                        fprintf('    %s calls: %s\n', localName, externalStruct.funcs{i}{j});
                    end
                end
            end
            fprintf('------\n');
        end
        
        error('External dependencies cannot be packaged in a MATLAB executable');
    end
    
    compileMATLAB('LEVer', bindir, {}, toolboxStruct.deps);
    compileMATLAB('LEVER_SegAndTrackFolders', bindir, {}, toolboxStruct.deps);
    compileMATLAB('Segmentor', bindir, {}, toolboxStruct.deps);
    
    fprintf('\n');
    
%     mcrfile = mcrinstaller();
%     system(['copy "' mcrfile '" "' fullfile(bindir,'.') '"']);
    
    verSuffix = Helper.GetVersion('file');
    zip(fullfile(bindir,['LEVer' verSuffix '.zip']), {'*.exe', '*.bat'}, bindir);
    
    toc(totalTime)
end

function [vsStruct comparch] = setupCompileTools()
    vsStruct.vstoolroot = getenv('VS100COMNTOOLS');
    if ( isempty(vsStruct.vstoolroot) )
        error('Cannot compile MTC and mexMAT without Visual Studio 2010');
    end

    comparch = computer('arch');
    if ( strcmpi(comparch,'win64') )
        vsStruct.buildbits = '64';
        vsStruct.buildenv = fullfile(vsStruct.vstoolroot,'..','..','vc','bin','amd64','vcvars64.bat');
        vsStruct.buildplatform = 'x64';
    elseif ( strcmpi(comparch,'win32') )
        vsStruct.buildbits = '32';
        vsStruct.buildenv = fullfile(vsStruct.vstoolroot,'..','..','vc','bin','vcvars32.bat');
        vsStruct.buildplatform = 'win32';
    else
        error('Only windows 32/64-bit builds are currently supported');
    end
    
    system(['"' vsStruct.buildenv '"' ]);
    clear mex;
end

function compileMEX(projectName, vsStruct)
    compileTime = tic();
    fprintf('\nVisual Studio Compiling: %s...\n', [projectName '.mexw' vsStruct.buildbits]);
    
    projectRoot = fullfile('..','c',projectName);
    
    result = system(['"' fullfile(vsStruct.vstoolroot,'..','IDE','devenv.com') '"' ' /build "Release|' vsStruct.buildplatform '" "' projectRoot '.sln"']);
    if ( result ~= 0 )
        error('MEX compile failed.');
    end
    
    system(['copy ' fullfile(projectRoot, ['Release_' vsStruct.buildplatform], [projectName '.dll']) ' ' fullfile('.', [projectName '.mexw' vsStruct.buildbits])]);
    fprintf('Done (%f sec)\n\n', toc(compileTime));
end

function compileEXE(projectName, vsStruct, bindir)
    compileTime = tic();
    fprintf('\nVisual Studio Compiling: %s...\n', [projectName '.exe']);
    
    projectRoot = fullfile('..','c',projectName);
    
    result = system(['"' fullfile(vsStruct.vstoolroot,'..','IDE','devenv.com') '"' ' /build "Release|' vsStruct.buildplatform '" "' projectRoot '.sln"']);
    if ( result ~= 0 )
%         error('EXE compile failed.');
    end
    
    system(['copy ' fullfile(projectRoot, ['Release_' vsStruct.buildplatform], [projectName '.exe']) ' ' fullfile('.', [projectName '.exe'])]);
    system(['copy ' fullfile(projectRoot, ['Release_' vsStruct.buildplatform], [projectName '.exe']) ' ' fullfile(bindir,'.')]);
    
    fprintf('Done (%f sec)\n\n', toc(compileTime));
end

function compileMATLAB(projectName, bindir, extrasList, toolboxList)
    compileTime = tic();
    if ( ~exist('extrasList','var') )
        extrasList = {};
    end
    extrasList = vertcat({'LEVER_logo.tif';
                          '+Segmentation\*FrameSegmentor.m';
                          '+Helper\GetVersion.m';
                          '+Helper\VersionInfo.m'}, extrasList);
    
	extraCommand = '';
    if ( ~isempty(extrasList) )
        extraElems = cellfun(@(x)([' -a ' x]),extrasList, 'UniformOutput',0);
        extraCommand = [extraElems{:}];
    end
    
    if ( ~exist('toolboxList','var') )
        toolboxList = {};
    end
    
    toolboxAddCommand = '';
    if ( ~isempty(toolboxList) )
        toolboxElems = cellfun(@(x)([' -p "' x '"']), toolboxList, 'UniformOutput',0);
        toolboxAddCommand = ['-N' toolboxElems{:}];
    end
    
    fprintf('\nMATLAB Compiling: %s...\n', projectName);
    result = system(['mcc -v -R -startmsg -m ' projectName '.m ' toolboxAddCommand extraCommand]);
    if ( result ~= 0 )
        error('MATLAB compile failed.');
    end
    
    system(['copy ' projectName '.exe ' fullfile(bindir,'.')]);
    
    fprintf('Done (%f sec)\n', toc(compileTime));
end

