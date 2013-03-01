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

vstoolroot = getenv('VS100COMNTOOLS');
if ( isempty(vstoolroot) )
    error('Cannot compile MTC and mexMAT without Visual Studio 2010');
end

comparch = computer('arch');
if ( strcmpi(comparch,'win64') )
    buildbits = '64';
    buildenv = fullfile(vstoolroot,'..','..','vc','bin','amd64','vcvars64.bat');
    buildplatform = 'x64';
    bindir = '..\..\bin64';
elseif ( strcmpi(comparch,'win32') )
    buildbits = '32';
    buildenv = fullfile(vstoolroot,'..','..','vc','bin','vcvars32.bat');
    buildplatform = 'win32';
    bindir = '..\..\bin';
else
    error('Only windows 32/64-bit builds are currently supported');
end

if ( ~exist(bindir,'dir') )
    mkdir(bindir);
end

system(['"' buildenv '"' ]);

tic();
fprintf('Visual Studio Compiling: %s...\n', 'MTC.exe');
system(['"' fullfile(vstoolroot,'..','IDE','devenv.com') '"' ' /build "Release|' buildplatform '" "..\c\MTC.sln"']);
fprintf('Done (%f sec)\n', toc());

tic();
fprintf('\nVisual Studio Compiling: %s...\n', ['mexMAT.mexw' buildbits]);
system(['"' fullfile(vstoolroot,'..','IDE','devenv.com') '"' ' /build "Release|' buildplatform '" "..\c\mexMAT.sln"']);
fprintf('Done (%f sec)\n\n', toc());

tic();
fprintf('\nVisual Studio Compiling: %s...\n', ['mexDijkstra.mexw' buildbits]);
system(['"' fullfile(vstoolroot,'..','IDE','devenv.com') '"' ' /build "Release|' buildplatform '" "..\c\mexDijkstra.sln"']);
fprintf('Done (%f sec)\n\n', toc());

tic();
fprintf('\nVisual Studio Compiling: %s...\n', ['mexIntegrityCheck.mexw' buildbits]);
system(['"' fullfile(vstoolroot,'..','IDE','devenv.com') '"' ' /build "Release|' buildplatform '" "..\c\mexIntegrityCheck.sln"']);
fprintf('Done (%d sec)\n\n', toc());

tic();
fprintf('\nVisual Studio Compiling: %s...\n', ['mexHashData.mexw' buildbits]);
system(['"' fullfile(vstoolroot,'..','IDE','devenv.com') '"' ' /build "Release|' buildplatform '" "..\c\mexHashData.sln"']);
fprintf('Done (%d sec)\n\n', toc());

tic();
fprintf('\nVisual Studio Compiling: %s...\n', ['mexCCDistance.mexw' buildbits]);
system(['"' fullfile(vstoolroot,'..','IDE','devenv.com') '"' ' /build "Release|' buildplatform '" "..\c\mexCCDistance.sln"']);
fprintf('Done (%f sec)\n\n', toc());

tic();
fprintf('Visual Studio Compiling: %s...\n', 'HematoSeg.exe');
system(['"' fullfile(vstoolroot,'..','IDE','devenv.com') '"' ' /build "Release|' buildplatform '" "..\c\HematoSeg.sln"']);
fprintf('Done (%f sec)\n', toc());

tic();
fprintf('Visual Studio Compiling: %s...\n', 'GrayScaleCrop.exe');
system(['"' fullfile(vstoolroot,'..','IDE','devenv.com') '"' ' /build "Release|' buildplatform '" "..\c\GrayScaleCrop.sln"']);
fprintf('Done (%f sec)\n', toc());

% clears out mex cache so src/*.mexw(32/64) can be overwritten
clear mex
system(['copy ..\c\mexMAT\Release_' buildplatform '\mexMAT.dll .\mexMAT.mexw' buildbits]);
system(['copy ..\c\mexDijkstra\Release_' buildplatform '\mexDijkstra.dll .\mexDijkstra.mexw' buildbits]);
system(['copy ..\c\mexIntegrityCheck\Release_' buildplatform '\mexIntegrityCheck.dll .\mexIntegrityCheck.mexw' buildbits]);
system(['copy ..\c\MTC\Release_' buildplatform '\MTC.exe .\']);
system(['copy ..\c\MTC\Release_' buildplatform '\MTC.exe ' bindir]);
system(['copy ..\c\HematoSeg\Release_' buildplatform '\HematoSeg.exe .\']);
system(['copy ..\c\HematoSeg\Release_' buildplatform '\HematoSeg.exe ' bindir]);
system(['copy ..\c\GrayScaleCrop\Release_' buildplatform '\GrayScaleCrop.exe .\']);
system(['copy ..\c\GrayScaleCrop\Release_' buildplatform '\GrayScaleCrop.exe ' bindir]);

mcrfile = mcrinstaller();
system(['copy "' mcrfile '" "' bindir '\"']);

tic();
fprintf('\nMATLAB Compiling: %s...\n', 'LEVer');
!mcc -R -startmsg -m LEVer.m -a LEVER_logo.tif -a +Helper\GetVersion.m -a +Helper\VersionInfo.m
fprintf('Done (%f sec)\n', toc());

tic();
fprintf('\nMATLAB Compiling: %s...\n', 'Segmentor');
!mcc -R -startmsg -m Segmentor.m -a +Segmentation\*FrameSegmentor.m -a +Helper\GetVersion.m -a +Helper\VersionInfo.m
fprintf('Done (%f sec)\n', toc());

tic();
fprintf('\nMATLAB Compiling: %s...\n', 'LEVER_SegAndTrackFolders');
!mcc -R -startmsg -m LEVER_SegAndTrackFolders.m -a +Helper\GetVersion.m -a +Helper\VersionInfo.m
fprintf('Done (%f sec)\n', toc());

% tic();
% fprintf('\nMATLAB Compiling: %s...\n', 'LinkTreeFolders');
% mcc -R -startmsg -m LinkTreeFolders.m
% fprintf('Done (%d sec)\n', toc());

fprintf('\n');

system(['copy LEVer.exe ' fullfile(bindir,'.')]);
system(['copy Segmentor.exe ' fullfile(bindir,'.')]);
system(['copy LEVER_SegAndTrackFolders.exe ' fullfile(bindir,'.')]);
system(['copy LinkTreeFolders.exe ' fullfile(bindir,'.')]);

if(isempty(dir('.\MTC.exe')) || isempty(dir(fullfile(bindir,'MTC.exe'))))
    warndlg('Make sure that MTC.exe is in the same dir as LEVer.exe and LEVer MATLAB src code');
end
toc(totalTime)
