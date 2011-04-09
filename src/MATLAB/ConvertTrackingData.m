function ConvertTrackingData(objHulls,gConnect)
%Takes the data structure from the tracking data and creates LEVer's data
%scheme

%--Eric Wait

global CONSTANTS Costs HashedCells CellHulls CellFamilies

%Initialize CONSTANTS
CONSTANTS.imageSize = unique([objHulls(:).imSize]);
CONSTANTS.maxPixelDistance = 40;
CONSTANTS.maxCenterOfMassDistance = 80;
CONSTANTS.minParentCandidateTimeFrame = 5;
CONSTANTS.minParentHistoryTimeFrame = 5;
CONSTANTS.minParentFuture = 5;
CONSTANTS.minFamilyTimeFrame = 5;
CONSTANTS.maxFrameDifference = 5;
CONSTANTS.historySize = 50;
CONSTANTS.clickMargin = 500;
Costs = gConnect;

%Initialize Structures
HashedCells = cell(0,length(objHulls));
CellHulls = struct(...
    'time',             {objHulls(1).t},...
    'points',           {objHulls(1).pts},...
    'centerOfMass',     {objHulls(1).COM},...
    'indexPixels',      {objHulls(1).indPixels},...
    'deleted',          {0});

if objHulls(1).inID == 0
    NewCellFamily(1,objHulls(1).t);
else
    AddHullToTrack(1,[],objHulls(1).inID);
end

%loop through the data 
for i=2:length(objHulls)
    if(i<=length(CellHulls)+1 || ~isempty(CellHulls(i).time))
        addHull(i);
    end
%     CellHulls(i).time            =  objHulls(i).t;
%     CellHulls(i).points          =  objHulls(i).pts;
%     CellHulls(i).centerOfMass    =  objHulls(i).COM;
%     CellHulls(i).indexPixels     =  objHulls(i).indPixels;
%     CellHulls(i).deleted         =  0;
%     
%     if objHulls(i).inID == 0
%         NewCellFamily(i,objHulls(i).t);
%     else       
%         AddHullToTrack(i,[],objHulls(i).inID);
%     end
end

%create the family trees
ProcessNewborns(1:length(CellFamilies));

    function addHull(num)
        CellHulls(num).time            =  objHulls(num).t;
        CellHulls(num).points          =  objHulls(num).pts;
        CellHulls(num).centerOfMass    =  objHulls(num).COM;
        CellHulls(num).indexPixels     =  objHulls(num).indPixels;
        CellHulls(num).deleted         =  0;
        
        if objHulls(num).inID > length(CellHulls)+1
            if objHulls(objHulls(num).inID).inID == 0
                NewCellFamily(num,objHulls(objHulls(num).inID).t);
            else
                addHull(objHulls(num).inID);
            end
        end
        
        if objHulls(num).inID == 0
            NewCellFamily(num,objHulls(num).t);
        else
            AddHullToTrack(num,[],objHulls(num).inID);
        end
        
        if objHulls(num).outID > length(CellHulls)+1
            addHull(objHulls(num).outID);
        end
    end
end
