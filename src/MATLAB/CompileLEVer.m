tic
mcc -m LEVer.m -d ..\..\bin\.
mcc -m Segmentor.m
system('copy Segmentor.exe ..\..\bin\.');
if(isempty(dir('.\MTC.exe')) || isempty(dir('..\..\bin\MTC.exe')))
    warndlg('Make sure that MTC.exe is in the same dir as LEVer.exe and LEVer MATLAB src code');
end
toc
