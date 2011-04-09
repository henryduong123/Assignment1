function MakeMovie(filename, fps, outRes)

%--Mark Winter

global CONSTANTS Figures HashedCells;

axHandles = [get(Figures.cells.handle, 'CurrentAxes') get(Figures.tree.handle, 'CurrentAxes')];

lims.cells = [get(axHandles(1), 'XLim'); get(axHandles(1), 'YLim')];
lims.tree = [get(axHandles(2), 'XLim'); get(axHandles(2), 'YLim')];

figpos.cells = get(Figures.cells.handle, 'Position');
figpos.tree = get(Figures.tree.handle, 'Position');

spc = 10;
set(axHandles(2), 'YLim', [lims.tree(2,1)-spc lims.tree(2,2)+spc]);

cellSz = GetPixelSize(axHandles(1));
cellApsect = cellSz(1) / cellSz(2);

treeSz = GetPixelSize(axHandles(2));
treeApsect = treeSz(1) / treeSz(2);

outCellSz = floor([outRes(2)*cellApsect outRes(2)]);
outTreeSz = [outRes(1)-outCellSz(1) outRes(2)];

oldtime = Figures.time;

%     movfile = avifile(fname, 'Compression','cinepak', 'fps',fps);

if ( ~exist(filename,'dir') )
    mkdir(filename);
end

save(fullfile(filename,'params.mat'), 'outRes', 'lims');

%     set(axHandles(1), 'XLim', [1 );

for t=1:length(HashedCells)
    Figures.time = t;
    
    set(Figures.cells.timeLabel,'String',['Time: ' num2str(Figures.time)]);
    set(Figures.tree.timeLabel,'String',['Time: ' num2str(Figures.time)]);
    UpdateTimeIndicatorLine();
    SetPixelSize(axHandles(2), outTreeSz);
    treeFrm = getframe(axHandles(2));
    
    DrawCells();
    SetPixelSize(axHandles(1), outCellSz);
    cellFrm = getframe(axHandles(1));
    
    fullFrm = cellFrm;
    fullFrm.cdata = [cellFrm.cdata(1:outCellSz(2),1:outCellSz(1),:) treeFrm.cdata(1:outTreeSz(2),1:outTreeSz(1),:)];
    
    imwrite(fullFrm.cdata, fullfile(filename,[filename '_' num2str(t,'%04d') '.tif']), 'tif');
    
    %         movfile = addframe(movfile,fullFrame);
end

%     movfile = close(movfile);

Figures.time = oldtime;
set(Figures.cells.timeLabel,'String',['Time: ' num2str(Figures.time)]);
set(Figures.tree.timeLabel,'String',['Time: ' num2str(Figures.time)]);

set(Figures.cells.handle, 'Position',figpos.cells);
set(Figures.tree.handle, 'Position',figpos.tree);
UpdateTimeIndicatorLine();
DrawCells();
end