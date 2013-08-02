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

defaultPath = fileparts(CONSTANTS.matFullFile);
defaultFile = [CONSTANTS.datasetName '.mp4'];

[movieFile, moviePath] = uiputfile('*.mp4', 'Save Movie', fullfile(defaultPath, defaultFile));
if ( movieFile == 0 )
    return;
end

movieFile = fullfile(moviePath, movieFile);

endAns = inputdlg('Enter stop frame for movie:', 'Movie end time', 1, {num2str(length(HashedCells))});
if ( isempty(endAns) )
    return;
end

nframes = str2double(endAns);
nframes = max(nframes, 20);
nframes = min(nframes, length(HashedCells));

tic

oldDrawOffTree = get(Figures.cells.menuHandles.treeLabelsOn, 'Checked');
oldTreePos = get(Figures.tree.handle, 'Position');
oldCellPos = get(Figures.cells.handle, 'Position');

set(Figures.cells.menuHandles.treeLabelsOn, 'Checked','off');
UI.DrawTree(Figures.tree.familyID, nframes);

movieDims = [1920 1080];

xLim = get(get(Figures.cells.handle, 'CurrentAxes'),'XLim');
yLim = get(get(Figures.cells.handle, 'CurrentAxes'),'YLim');

mp=get(0,'monitorpositions');
idxPrimaryMonitor = find(mp(:,1)==1 & mp(:,2)==1);
if isempty(idxPrimaryMonitor)
    fprintf(1,'could not locate primary monitor');
    Error.LogAction('GenerateAVI: could not locate primary monitor',0,0);
    return;
end

mp = mp(idxPrimaryMonitor,:);

if ( mp(3)<(movieDims(1)/2) || mp(4)<movieDims(2) )
    fprintf(1,'monitor resolution too low for %d by %d video', movieDims(1), movieDims(2));
    Error.LogAction('GenerateAVI: monitor resolution too low for %d by %d video',0,0);
end
    
set(Figures.cells.handle,'position',[mp(3)-(movieDims(1)/2) mp(4)-movieDims(2)  (movieDims(1)/2) movieDims(2)]);   
set(Figures.tree.handle,'position',[mp(3)-(movieDims(1)/2) mp(4)-movieDims(2)  (movieDims(1)/2) movieDims(2)]);

vidObj = VideoWriter(movieFile, 'MPEG-4');
vidObj.Quality = 100;
vidObj.FrameRate = 20;
open(vidObj);

tStart = 1;
tEnd = nframes;

for t=tStart:tEnd
    UI.TimeChange(t);
    UI.Progressbar(t/nframes);

    figure(Figures.cells.handle)

    X=getframe();
    i1=X.cdata;

    figure(Figures.tree.handle)
    X=getframe();
    i2=X.cdata;

    dim = [movieDims(2) (movieDims(1)/2)];

    i1 = imresize(i1, [dim(1) dim(2)]);
    i2 = imresize(i2, [dim(1) dim(2)]);

    icomp=[i1 i2];
    fr = im2frame(icomp);
    writeVideo(vidObj, fr);
end

close(vidObj);

set(Figures.cells.menuHandles.treeLabelsOn, 'Checked',oldDrawOffTree);

set(Figures.tree.handle, 'Position',oldTreePos);
set(Figures.cells.handle, 'Position',oldCellPos);

UI.DrawTree(Figures.tree.familyID);

tElapsed = toc;
Error.LogAction('GenerateAVI: elapsed time',tElapsed,0);
