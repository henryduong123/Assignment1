function convert()
%preallocate tables for speed

global CellFamilies CellHulls HashedCells Costs CONSTANTS Figures Colors
%CONSTANTS.datasetName = 'ER81_E12pt5_0527090025_3_3AC05_07';
CONSTANTS.datasetName = 'ER81_E12_0527090025_3_3AC03_02';
%CONSTANTS.datasetName = 'ER81_E12pt5_0527090025_3_2AB02_05';
data = [CONSTANTS.datasetName ' tracked_hulls.mat'];
CONSTANTS.rootFolder = ['..\..\Templetiffs\Temple Lineages\' CONSTANTS.datasetName '\'];
load(data);
load 'colors.mat'

Colors = colors;
Costs = gConnect;

CONSTANTS.ImageSize = unique([objHulls(:).imSize]);
CONSTANTS.maxPixelDistance = 40;
CONSTANTS.maxCenterOfMassDistance = 80;
CONSTANTS.minParentCandidateTimeFrame = 5;
CONSTANTS.minParentHistoryTimeFrame = 5;
CONSTANTS.minFamilyTimeFrame = 5;
CONSTANTS.maxFrameDifference = 1;

HashedCells = cell(0,length(objHulls));
i=1;

CellHulls = struct(...
    'time',             {objHulls(i).t},...
    'points',           {objHulls(i).pts},...
    'centerOfMass',     {objHulls(i).COM},...
    'indexPixels',      {objHulls(i).indPixels});

if objHulls(i).inID == 0
    NewCellFamily(i,objHulls(i).t);
else
    AddHullToTrack(i,[],objHulls(i).inID);
end

for i=2:length(objHulls)
    CellHulls(i).time            =  objHulls(i).t;
    CellHulls(i).points          =  objHulls(i).pts;
    CellHulls(i).centerOfMass    =  objHulls(i).COM;
    CellHulls(i).indexPixels     =  objHulls(i).indPixels;
    
    if objHulls(i).inID == 0
        NewCellFamily(i,objHulls(i).t);
    else       
        AddHullToTrack(i,[],objHulls(i).inID);
    end
end

ProcessNewborns();
Figures.tree = figure;
Figures.cells = figure;

% for i=1:length(CellFamilies)
%     if(isempty(CellFamilies(i).tracks)),return,end
%     DrawTree(i);
%     DrawCells(450,i);
%     pause(1);
%     i
% end
DrawTree(10);
DrawCells(1,10);
end
