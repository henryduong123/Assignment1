% GenerateAVI.m - Create AVI movie from currently open LEVer dataset.

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

function GenerateAVI(src, evt)

global Figures CONSTANTS HashedCells

tic

outfile =  [ CONSTANTS.datasetName ' _cine.avi'];
aviobj = avifile(outfile,'compression','cinepak');

nframes = length(HashedCells);

xLim = get(get(Figures.cells.handle, 'CurrentAxes'),'XLim');
yLim = get(get(Figures.cells.handle, 'CurrentAxes'),'YLim');
mp=get(0,'monitorpositions');
idxPrimaryMonitor = find(mp(:,1)==1 & mp(:,2)==1);
if isempty(idxPrimaryMonitor)
    fprintf(1,'could not locate primary monitor');
    Error.LogAction('GenerateAVI: could not locate primary monitor',0,0);
    return;
end

mp=mp(idxPrimaryMonitor,:);

if mp(3)<960 || mp(4)<1080
    fprintf(1,'monitor resolution too low for 1080p video');
    Error.LogAction('GenerateAVI: monitor resolution too low for 1080p video',0,0);
end
    
set(Figures.cells.handle,'outerposition',[mp(3)-960 mp(4)-1080  960 1080]);   
set(Figures.tree.handle,'outerposition',[mp(3)-960 mp(4)-1080  960 1080]);

for t=1:nframes
    UI.TimeChange(t);
    UI.Progressbar(t/nframes);
    
    figure(Figures.cells.handle)
    
    X=getframe();
    i1=X.cdata;
    
    figure(Figures.tree.handle)
    X=getframe();
    i2=X.cdata;
    
    dim = [1080 960];
    
    i1 = imresize(i1,[dim(1) dim(2)]);
    i2 = imresize(i2,[dim(1) dim(2)]);
    
    icomp=[i1 i2];
    fr = im2frame(icomp);
    aviobj = addframe(aviobj,fr);
end

aviobj = close(aviobj);

tElapsed = toc;
Error.LogAction('GenerateAVI: elapsed time',tElapsed,0);