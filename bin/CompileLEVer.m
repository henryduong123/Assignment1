mcc -m ../LEVer.m
mcc -m ../Segmentor.m
if(isempty(dir('./MTC.exe')))
    warndlg('Make sure that MTC.exe is in the same dir as LEVer.exe');
end