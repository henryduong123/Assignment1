% CompileLEVer.m - Script to build LEVer and its dependencies

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
%     Copyright 2011-2016 Andrew Cohen
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
    
    %% Build FrameSegmentor help information into a function for use in compiled LEVER
    Dev.MakeSegHelp();

    %% Setup visual studio for MEX compilation
    [vsStruct comparch] = setupCompileTools();
    
    bindir = '..\..\bin';
    if ( strcmpi(comparch,'win64') )
        bindir = '..\..\bin64';
    end

    if ( ~exist(bindir,'dir') )
        mkdir(bindir);
    end
    
    %% Compile all MEX files
    outputFiles = {};
    
    newOutput = compileMEX('mexMAT', vsStruct);
    outputFiles = [outputFiles; {newOutput}];
    
    newOutput = compileMEX('Tracker', vsStruct);
    outputFiles = [outputFiles; {newOutput}];
    
    newOutput = compileMEX('mexDijkstra', vsStruct);
    outputFiles = [outputFiles; {newOutput}];
    
    newOutput = compileMEX('mexGraph', vsStruct);
    outputFiles = [outputFiles; {newOutput}];
    
    newOutput = compileMEX('mexIntegrityCheck', vsStruct);
    outputFiles = [outputFiles; {newOutput}];
    
    newOutput = compileMEX('mexHashData', vsStruct);
    outputFiles = [outputFiles; {newOutput}];
    
    %% Compile LEVER, Segmentor, and batch LEVER_SegAndTrackFolders.
    
    addImgs = {'+UI\backFrame.png'; '+UI\forwardFrame.png'; '+UI\pause.png';'+UI\play.png';'+UI\stop.png'};
    newOutput = compileMATLAB('LEVer', bindir, addImgs, initStruct.toolboxList);
    outputFiles = [outputFiles; {newOutput}];
    
    newOutput = compileMATLAB('LEVER_SegAndTrackFolders', bindir, {}, initStruct.toolboxList);
    outputFiles = [outputFiles; {newOutput}];
    
    newOutput = compileMATLAB('Segmentor', bindir, {}, initStruct.toolboxList);
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

function [vsStruct comparch] = setupCompileTools()
    vsStruct.vstoolroot = getenv('VS140COMNTOOLS');
    if ( isempty(vsStruct.vstoolroot) )
        error('Cannot compile MEX files without Visual Studio 2015');
    end
    
    setenv('MATLAB_DIR', matlabroot());

    comparch = computer('arch');
    if ( strcmpi(comparch,'win64') )
        vsStruct.buildbits = '64';
        vsStruct.buildenv = fullfile(vsStruct.vstoolroot,'..','..','vc','bin','amd64','vcvars64.bat');
        vsStruct.buildplatform = 'x64';
    else
        error('Only windows 64-bit builds are currently supported');
    end
    
    system(['"' vsStruct.buildenv '"' ]);
    clear mex;
end

function outputFile = compileMEX(projectName, vsStruct)
    compileTime = tic();
    outputFile = [projectName '.mexw' vsStruct.buildbits];
    fprintf('\nVisual Studio Compiling: %s...\n', outputFile);
    
    projectRoot = fullfile('..','c',projectName);
    
    result = system(['"' fullfile(vsStruct.vstoolroot,'..','IDE','devenv.com') '"' ' /build "Release|' vsStruct.buildplatform '" "' projectRoot '.sln"']);
    if ( result ~= 0 )
        error([projectName ': MEX compile failed.']);
    end
    
    system(['copy ' fullfile(projectRoot, ['Release_' vsStruct.buildplatform], [projectName '.dll']) ' ' fullfile('.', [projectName '.mexw' vsStruct.buildbits])]);
    fprintf('Done (%f sec)\n\n', toc(compileTime));
end

function outputFile = compileEXE(projectName, vsStruct, bindir)
    compileTime = tic();
    outputFile = [projectName '.exe'];
    fprintf('\nVisual Studio Compiling: %s...\n', outputFile);
    
    projectRoot = fullfile('..','c',projectName);
    
    result = system(['"' fullfile(vsStruct.vstoolroot,'..','IDE','devenv.com') '"' ' /build "Release|' vsStruct.buildplatform '" "' projectRoot '.sln"']);
    if ( result ~= 0 )
        error([projectName ': EXE compile failed.']);
    end
    
    system(['copy ' fullfile(projectRoot, ['Release_' vsStruct.buildplatform], [projectName '.exe']) ' ' fullfile('.', [projectName '.exe'])]);
    system(['copy ' fullfile(projectRoot, ['Release_' vsStruct.buildplatform], [projectName '.exe']) ' ' fullfile(bindir,'.')]);
    
    fprintf('Done (%f sec)\n\n', toc(compileTime));
end

function outputFile = compileMATLAB(projectName, bindir, extrasList, toolboxList)
    compileTime = tic();
    
    outputFile = [projectName '.exe'];
    
    if ( ~exist('extrasList','var') )
        extrasList = {};
    end
    extrasList = vertcat({'LEVER_logo.tif';
                          '+Segmentation\FrameSegmentor_*.m';
                          '+Dev\GetVersion.m';
                          '+Dev\VersionInfo.m'}, extrasList);
    
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
