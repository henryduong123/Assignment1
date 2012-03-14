function [objTracks gConnect hashedHulls] = RereadTrackData(DatasetName)
global CellHulls

th=max([CellHulls.time]);
hashedHulls=cell(th,1);

objTracks = struct('Label',cell(1,length(CellHulls)), 'ccc',cell(1,length(CellHulls)),...
                   'outID',{0}, 'inID',{0});

% reset tracking info
for i=1:length(CellHulls)
    hashedHulls{CellHulls(i).time} = [hashedHulls{CellHulls(i).time} i];
end

fname=['.\segmentationData\Tracked_' DatasetName '.txt'];
fid=fopen(fname,'r');
bDone=0;
TrackList=[];
while ~bDone
    dd=fscanf(fid,'%d,%d,%d,%d,%d\n',5);
    if -1==dd(1)
       bDone=1;
       break
    end
    TrackList=[TrackList;dd'];
end

bDone=0;
InList=[];
while ~bDone
    dd=fscanf(fid,'%d,%d,%f\n',3);
    if isempty(dd)
       bDone=1;
       break
    end
    InList=[InList;dd'];
end

fclose(fid);

for i=1:size(TrackList,1)
    th=hashedHulls{TrackList(i,2)}; 
    thk=hashedHulls{TrackList(i,3)}; 
    
    o1=th(TrackList(i,4));
    o2=thk(TrackList(i,5));
    
    objTracks(o1).Label=TrackList(i,1);
    objTracks(o2).Label=TrackList(i,1);
    objTracks(o1).outID=o2;
    objTracks(o2).inID=o1;
end

cmap=hsv(256);
for i=1:max([objTracks.Label])
    oi = find([objTracks.Label]==i);
    ccc=cmap(round(255*rand())+1,:);
    for j=1:length( oi)
        objTracks(oi(j)).ccc=ccc;
    end
end

nLabel=max([objTracks.Label])+1;
for n=1:length(objTracks)
    if (objTracks(n).Label>0)
        continue;
    end
    
    objTracks(n).Label = nLabel;
    nLabel=nLabel+1;
    ccc=cmap(round(255*rand())+1,:);
    objTracks(n).ccc=ccc;
end

gConnect=sparse([],[],[],length(CellHulls),length(CellHulls),round(.1*length(CellHulls)));
for i=1:size(InList,1)
    gConnect(InList(i,2),InList(i,1))=InList(i,3);
end

end