function [objTracks gConnect] = RereadTrackData(DatasetDir, DatasetName)
global CellHulls

th=max([CellHulls.time]);
hashedHulls=cell(th,1);

objTracks = struct('Label',cell(1,length(CellHulls)), 'ccc',cell(1,length(CellHulls)),...
                   'outID',{0}, 'inID',{0});

% reset tracking info
for i=1:length(CellHulls)
    hashedHulls{CellHulls(i).time} = [hashedHulls{CellHulls(i).time} i];
end

fname = fullfile(DatasetDir,['Tracked_' DatasetName '.txt']);
fid=fopen(fname,'rt');
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
dd=textscan(fid,'%f,%f,%f');
InList=[dd{1},dd{2},dd{3}];

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

nLabel=max([objTracks.Label])+1;
for n=1:length(objTracks)
    if (objTracks(n).Label>0)
        continue;
    end
    
    objTracks(n).Label = nLabel;
    nLabel=nLabel+1;
end

gConnect=sparse(InList(:,2),InList(:,1),InList(:,3),length(CellHulls),length(CellHulls));
end