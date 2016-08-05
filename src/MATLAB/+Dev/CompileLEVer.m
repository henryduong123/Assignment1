% CompileLEVer.m - Script to build LEVer and its dependencies

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
%     Copyright 2016 Drexel University
%
%     This file is part of LEVer - the tool for stem cell lineaging. See
%     http://n2t.net/ark:/87918/d9rp4t for details
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

function CompileLEVer(forceVersion)
    totalTime = tic();
    
    if ( ~exist('forceVersion','var') )
        forceVersion = '';
    end
    
    %% General compiler setup: Deals with version updates and pulls external dependencies
    initStruct = Dev.InitCompiler('LEVER',forceVersion);
    if ( isempty(initStruct) )
        % User exited the build due to error or uncommited dependencies.
        return;
    end
    
    %% Build FrameSegmentor help information into a function for use in compiled LEVER
    Dev.MakeSegHelp();

    %% Setup visual studio for MEX compilation
    setenv('MATLAB_DIR', matlabroot());
    [compStruct,comparch] = Dev.SetupCPPCompiler('vs2015');
    
    bindir = '..\..\bin';
    if ( strcmpi(comparch,'win64') )
        bindir = '..\..\bin64';
    end

    if ( ~exist(bindir,'dir') )
        mkdir(bindir);
    end
    
    %% Compile all MEX files
    outputFiles = {};
    
    newOutput = compileMEX('mexMAT', compStruct);
    outputFiles = [outputFiles; {newOutput}];
    
    newOutput = compileMEX('Tracker', compStruct);
    outputFiles = [outputFiles; {newOutput}];
    
    newOutput = compileMEX('mexDijkstra', compStruct);
    outputFiles = [outputFiles; {newOutput}];
    
    newOutput = compileMEX('mexGraph', compStruct);
    outputFiles = [outputFiles; {newOutput}];
    
    newOutput = compileMEX('mexIntegrityCheck', compStruct);
    outputFiles = [outputFiles; {newOutput}];
    
    newOutput = compileMEX('mexHashData', compStruct);
    outputFiles = [outputFiles; {newOutput}];
    
    %% Compile LEVER, Segmentor, and batch LEVER_SegAndTrackFolders.
    
    javaDeps = initStruct.javaList;
    addFiles = {'LEVER_logo.tif'; '+Segmentation\FrameSegmentor_*.m'; '+Dev\GetVersion.m'; '+Dev\VersionInfo.m'};
    addImgs = {'+UI\backFrame.png'; '+UI\forwardFrame.png'; '+UI\pause.png';'+UI\play.png';'+UI\stop.png'};
    
    newOutput = compileMATLAB('LEVer', bindir, [addFiles;javaDeps;addImgs], initStruct.toolboxList);
    outputFiles = [outputFiles; {newOutput}];
    
    newOutput = compileMATLAB('LEVER_SegAndTrackFolders', bindir, [addFiles;javaDeps], initStruct.toolboxList);
    outputFiles = [outputFiles; {newOutput}];
    
    newOutput = compileMATLAB('Segmentor', bindir, [addFiles;javaDeps], initStruct.toolboxList);
    outputFiles = [outputFiles; {newOutput}];
    
    fprintf('\n');
    
%     mcrfile = mcrinstaller();
%     system(['copy "' mcrfile '" "' fullfile(bindir,'.') '"']);
    
    bIsEXE = cellfun(@(x)(~isempty(x)), strfind(lower(outputFiles), '.exe'));
    exeOutputs = outputFiles(bIsEXE);
    
%     verSuffix = Dev.GetVersion('file');
%     zip(fullfile(bindir,['LEVer' verSuffix '.zip']), [exeOutputs; {'*.bat'}], bindir);
    
    toc(totalTime)
end

function outputFile = compileMEX(projectName, compStruct)
    compileTime = tic();
    outputFile = [projectName '.mexw' compStruct.buildbits];
    fprintf('\nVisual Studio Compiling: %s...\n', outputFile);
    
    projectRoot = fullfile('..','c',projectName);
    
    result = system(['"' fullfile(compStruct.toolroot,'..','IDE','devenv.com') '"' ' /build "Release|' compStruct.buildplatform '" "' projectRoot '.sln"']);
    if ( result ~= 0 )
        error([projectName ': MEX compile failed.']);
    end
    
    system(['copy ' fullfile(projectRoot, ['Release_' compStruct.buildplatform], [projectName '.dll']) ' ' fullfile('.', [projectName '.mexw' compStruct.buildbits])]);
    fprintf('Done (%f sec)\n\n', toc(compileTime));
end

function outputFile = compileEXE(projectName, compStruct, bindir)
    compileTime = tic();
    outputFile = [projectName '.exe'];
    fprintf('\nVisual Studio Compiling: %s...\n', outputFile);
    
    projectRoot = fullfile('..','c',projectName);
    
    result = system(['"' fullfile(compStruct.vstoolroot,'..','IDE','devenv.com') '"' ' /build "Release|' compStruct.buildplatform '" "' projectRoot '.sln"']);
    if ( result ~= 0 )
        error([projectName ': EXE compile failed.']);
    end
    
    system(['copy ' fullfile(projectRoot, ['Release_' compStruct.buildplatform], [projectName '.exe']) ' ' fullfile('.', [projectName '.exe'])]);
    system(['copy ' fullfile(projectRoot, ['Release_' compStruct.buildplatform], [projectName '.exe']) ' ' fullfile(bindir,'.')]);
    
    fprintf('Done (%f sec)\n\n', toc(compileTime));
end

function outputFile = compileMATLAB(projectName, bindir, extrasList, toolboxList)
    compileTime = tic();
    
    outputFile = [projectName '.exe'];
    
    if ( ~exist('extrasList','var') )
        extrasList = {};
    end
    
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
    
    fprintf('\nMATLAB Compiling: %s...\n', outputFile);
    result = system(['mcc -v -R -startmsg -m ' projectName '.m ' toolboxAddCommand extraCommand]);
    if ( result ~= 0 )
        error([projectName ': MATLAB compile failed.']);
    end
    
    system(['copy ' projectName '.exe ' fullfile(bindir,'.')]);
    
    fprintf('Done (%f sec)\n', toc(compileTime));
end
