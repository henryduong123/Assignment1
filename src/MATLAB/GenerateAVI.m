function GenerateAVI()

global Figures CONSTANTS HashedCells

tic

outfile =  [ CONSTANTS.datasetName ' _cine.avi'];
aviobj = avifile(outfile,'compression','cinepak');

nframes = length(HashedCells);

xLim = get(get(Figures.cells.handle, 'CurrentAxes'),'XLim');
yLim = get(get(Figures.cells.handle, 'CurrentAxes'),'YLim');
% dim = [2*floor(xLim(2)-xLim(1)) floor(yLim(2)-yLim(1))];
mp=get(0,'monitorpositions');
idxPrimaryMonitor = find(mp(:,1)==1 & mp(:,2)==1);
if isempty(idxPrimaryMonitor)
    fprintf(1,'could not locate primary monitor');
    LogAction('GenerateAVI: could not locate primary monitor',0,0);
    return;
end

mp=mp(idxPrimaryMonitor,:);

if mp(3)<960 || mp(4)<1080
    fprintf(1,'monitor resolution too low for 1080p video');
    LogAction('GenerateAVI: monitor resolution too low for 1080p video',0,0);
end

set(Figures.cells.handle,'position',[1 1  960 1080]);
outerpos = get(Figures.cells.handle,'outerposition');
    
set(Figures.cells.handle,'outerposition',[mp(3)-960 mp(4)-1080  960 1080]);   
set(Figures.tree.handle,'outerposition',[mp(3)-960 mp(4)-1080  960 1080]);

for t=1:nframes
    TimeChange(t);
    Progressbar(t/nframes);
    
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
LogAction('GenerateAVI: elapsed time',tElapsed,0);