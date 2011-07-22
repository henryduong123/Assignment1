%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
%     This file is part of LEVer.exe
%     (C) 2011 Andrew Cohen, Eric Wait and Mark Winter
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

tic

vstoolroot = getenv('VS90COMNTOOLS');
if ( isempty(vstoolroot) )
    error('Cannot compile MTC and mexMAT without Visual Studio 2008');
end

% buildDirList = {'..\c\MTC\Release' '..\c\MTC\Intermediate' '..\c\mexMAT\Release' '..\c\mexMAT\Intermediate'};
% 
% for i=1:length(buildDirList)
%     if ( exist(buildDirList{i},'dir') )
%         rmdir(buildDirList{i}, 's');
%     end
% end

system(['"' fullfile(vstoolroot,'..','IDE','devenv.com') '"' ' /build Release "..\c\MTC.sln"']);
system(['"' fullfile(vstoolroot,'..','IDE','devenv.com') '"' ' /build Release "..\c\mexMAT.sln"']);

% clears out mex cache so src/mexMAT.mexw32 can be overwritten
clear mex
system('copy ..\c\mexMAT\Release\mexMAT.dll .\mexMAT.mexw32');
system('copy ..\c\MTC\Release\MTC.exe .\');
system('copy ..\c\MTC\Release\MTC.exe ..\..\bin\');

mcc -m LEVer.m -d ..\..\bin\.
mcc -m Segmentor.m
system('copy Segmentor.exe ..\..\bin\.');
if(isempty(dir('.\MTC.exe')) || isempty(dir('..\..\bin\MTC.exe')))
    warndlg('Make sure that MTC.exe is in the same dir as LEVer.exe and LEVer MATLAB src code');
end
toc
