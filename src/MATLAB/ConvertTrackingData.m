function ConvertTrackingData(objHulls,gConnect)
%Takes the data structure from the tracking data and creates LEVer's data
%scheme

%--Eric Wait

global CONSTANTS Costs CellHulls CellFamilies CellTracks HashedCells ConnectedDist

%ensure that the globals are empty
Costs = [];
CellHulls = [];
CellFamilies = [];
CellTracks = [];
HashedCells = [];
ConnectedDist = [];

CONSTANTS.imageSize = unique([objHulls(:).imSize]);

Costs = gConnect;

%Initialize Structures
% HashedCells = cell(0,length(objHulls));
cellHulls = struct(...
    'time',             {},...
    'points',           {},...
    'centerOfMass',     {},...
    'indexPixels',      {},...
    'imagePixels',      {},...
    'deleted',          {});

%loop through the Hulls
parfor i=1:length(objHulls)
    cellHulls(i).time            =  objHulls(i).t;
    cellHulls(i).points          =  objHulls(i).pts;
    cellHulls(i).centerOfMass    =  objHulls(i).COM;
    cellHulls(i).indexPixels     =  objHulls(i).indPixels;
    cellHulls(i).imagePixels     =  objHulls(i).imPixels;
    cellHulls(i).deleted         =  0;
end
CellHulls = cellHulls;

%walk through the tracks
progress = 1;
iterations = length(objHulls);
hullList = [];
for i=length(objHulls):-1:1
    progress = progress+1;
    Progressbar(progress/iterations);
    if(any(ismember(hullList,i))),continue,end
    if(objHulls(i).inID~=0),continue,end
    hullList = addToTrack(i,hullList,objHulls);
end

%add any hulls that were missed
if(length(hullList)~=length(CellHulls))
    reprocess = find(ismember(1:length(CellHulls),hullList)==0);
    progress = 1;
    iterations = length(objHulls);
    for i=1:length(reprocess)
        progress = progress+1;
        Progressbar(progress/iterations);
        NewCellFamily(reprocess(i),objHulls(reprocess(i)).t);
    end
end
Progressbar(1);%clear it out

try
    TestDataIntegrity(1);
catch errormsg
    fprintf('\n%s\n',errormsg.message);
    ProgressBar(1);
end

%create the family trees
ProcessNewborns(1:length(CellFamilies));

end

function hullList = addToTrack(hull,hullList,objHulls)
%error checking
if(any(ismember(hullList,hull)) || objHulls(hull).inID ~= 0)
    %already part of a track
    return
end

NewCellFamily(hull,objHulls(hull).t);
hullList = [hullList hull];

while(objHulls(hull).outID~=0)
    hull = objHulls(hull).outID;
    if(any(ismember(hullList,hull))),break,end
    if(any(ismember(hullList,objHulls(hull).inID)))
        AddHullToTrack(hull,[],objHulls(hull).inID);
    else
        %this runs if there was an error in objHulls data structure
        NewCellFamily(hull,objHulls(hull).t);
    end
    hullList = [hullList hull];
end
end

