function [objHulls gConnect HashedHulls]=ReadTrackData(objHulls,DatasetName)
th=max([objHulls.t]);
HashedHulls=cell(th,1);

% reset tracking info
for n=1:length(objHulls)
    objHulls(n).Label=-1; 
    objHulls(n).inID=0;
    objHulls(n).outID=0;
    HashedHulls{objHulls(n).t}=[HashedHulls{objHulls(n).t};n];
end
fname=['.\Tracked_' DatasetName '.txt'];
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
    th=HashedHulls{TrackList(i,2)}; 
    thk=HashedHulls{TrackList(i,3)}; 
    o1=th(TrackList(i,4));
    o2=thk(TrackList(i,5));
    objHulls(o1).Label=TrackList(i,1);
    objHulls(o2).Label=TrackList(i,1);
    objHulls(o1).outID=o2;
    objHulls(o2).inID=o1;
end

cmap=hsv(256);
for i=1:max([objHulls.Label])
    oi = find([objHulls.Label]==i);
    ccc=cmap(round(255*rand())+1,:);
    for j=1:length( oi)
        objHulls(oi(j)).ccc=ccc;
    end
end
nLabel=max([objHulls.Label])+1;
for n=1:length(objHulls)
    [r c]=ind2sub(objHulls(n).imSize,objHulls(n).indPixels);
    objHulls(n).COM=mean([r c],1);    
    if objHulls(n).Label>0,continue,end
    objHulls(n).Label= nLabel;
    nLabel=nLabel+1;
    ccc=cmap(round(255*rand())+1,:);
    objHulls(n).ccc=ccc;
end

gConnect=sparse([],[],[],length(objHulls),length(objHulls),round(.1*length(objHulls)));
for i=1:size(InList,1)
    gConnect(InList(i,2),InList(i,1))=InList(i,3);
end
end

