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

tic

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

system(['"' fullfile(vstoolroot,'..','IDE','devenv.com') '"' ' /build "Release|' buildplatform '" "..\c\MTC.sln"']);
system(['"' fullfile(vstoolroot,'..','IDE','devenv.com') '"' ' /build "Release|' buildplatform '" "..\c\mexMAT.sln"']);
system(['"' fullfile(vstoolroot,'..','IDE','devenv.com') '"' ' /build "Release|' buildplatform '" "..\c\mexDijkstra.sln"']);
system(['"' fullfile(vstoolroot,'..','IDE','devenv.com') '"' ' /build "Release|' buildplatform '" "..\c\mexIntegrityCheck.sln"']);

% clears out mex cache so src/*.mexw(32/64) can be overwritten
clear mex
system(['copy ..\c\mexMAT\Release_' buildplatform '\mexMAT.dll .\mexMAT.mexw' buildbits]);
system(['copy ..\c\mexDijkstra\Release_' buildplatform '\mexDijkstra.dll .\mexDijkstra.mexw' buildbits]);
system(['copy ..\c\mexIntegrityCheck\Release_' buildplatform '\mexIntegrityCheck.dll .\mexIntegrityCheck.mexw' buildbits]);
system(['copy ..\c\MTC\Release_' buildplatform '\MTC.exe .\']);
system(['copy ..\c\MTC\Release_' buildplatform '\MTC.exe ' bindir]);

mcrfile = mcrinstaller();
system(['copy "' mcrfile '" "' bindir '\"']);

mcc -R -startmsg -m LEVer.m -a LEVER_logo.tif
mcc -R -startmsg -m Segmentor.m
mcc -R -startmsg -m LEVER_SegAndTrackFolders.m
mcc -R -startmsg -m LinkTreeFolders.m
system(['copy LEVer.exe ' fullfile(bindir,'.')]);
system(['copy Segmentor.exe ' fullfile(bindir,'.')]);
system(['copy LEVER_SegAndTrackFolders.exe ' fullfile(bindir,'.')]);
system(['copy LinkTreeFolders.exe ' fullfile(bindir,'.')]);

if(isempty(dir('.\MTC.exe')) || isempty(dir(fullfile(bindir,'MTC.exe'))))
    warndlg('Make sure that MTC.exe is in the same dir as LEVer.exe and LEVer MATLAB src code');
end
toc
