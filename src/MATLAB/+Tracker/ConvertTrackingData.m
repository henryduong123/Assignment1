% ConvertTrackingData.m - Takes the data structure from the tracking data
% and creates LEVer's data scheme

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

function ConvertTrackingData(objHulls,gConnect, features)

global CONSTANTS Costs GraphEdits CellHulls CellFeatures CellFamilies CellTracks HashedCells CellPhenotypes ConnectedDist Log

%ensure that the globals are empty
Costs = [];
GraphEdits = [];
CellHulls = [];
CellFamilies = [];
CellTracks = [];
HashedCells = [];
ConnectedDist = [];
CellPhenotypes = [];
Log = [];

CellFeatures = [];

CONSTANTS.imageSize = unique([objHulls(:).imSize]);

Costs = gConnect;
GraphEdits = sparse([], [], [], size(Costs,1), size(Costs,2), round(0.1*size(Costs,2)));

connDist = cell(1,length(objHulls));

%Initialize Structures
cellHulls = struct(...
    'time',             {},...
    'points',           {},...
    'centerOfMass',     {},...
    'indexPixels',      {},...
    'imagePixels',      {},...
    'deleted',          {},...
    'userEdited',       {});

%Initialize Structures
locCellFeatures = struct(...
    'darkRatio',        {},...
    'haloRatio',        {},...
    'igRatio',          {},...
    'darkIntRatio',     {},...
    'brightInterior',	{},...
    'polyPix',          {},...
    'perimPix',         {},...
    'igPix',            {},...
    'haloPix',          {});

CellPhenotypes = struct('descriptions', {{'died'}}, 'contextMenuID', {[]}, 'hullPhenoSet', {zeros(2,0)});

%loop through the Hulls
parfor i=1:length(objHulls)
    cellHulls(i).time            =  objHulls(i).t;
    cellHulls(i).points          =  objHulls(i).points;
    cellHulls(i).centerOfMass    =  objHulls(i).COM;
    cellHulls(i).indexPixels     =  objHulls(i).indPixels;
    cellHulls(i).imagePixels     =  objHulls(i).imPixels;
    cellHulls(i).deleted         =  0;
    cellHulls(i).userEdited      =  0;
    
    connDist{i} = updateConnectedDistance(objHulls(i), objHulls, objHulls(i).DarkConnectedHulls);
    
    locCellFeatures(i).darkRatio       = features(i).darkRatio;
    locCellFeatures(i).haloRatio       = features(i).haloRatio;
    locCellFeatures(i).igRatio         = features(i).igRatio;
    locCellFeatures(i).darkIntRatio	= features(i).darkIntRatio;
    locCellFeatures(i).brightInterior	= features(i).brightInterior;
    locCellFeatures(i).polyPix         = features(i).polyPix;
    locCellFeatures(i).perimPix        = features(i).perimPix;
    locCellFeatures(i).igPix           = features(i).igPix;
    locCellFeatures(i).haloPix         = features(i).haloPix;
end
ConnectedDist = connDist;
CellHulls = cellHulls;
CellFeatures = locCellFeatures;

%walk through the tracks
progress = 1;
iterations = length(objHulls);
hullList = [];
for i=length(objHulls):-1:1
    progress = progress+1;
    UI.Progressbar(progress/iterations);
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
        UI.Progressbar(progress/iterations);
        Families.NewCellFamily(reprocess(i),objHulls(reprocess(i)).t);
    end
end
UI.Progressbar(1);%clear it out

try
    errors = mexIntegrityCheck();
catch errormsg
    fprintf('\n%s\n',errormsg.message);
    UI.ProgressBar(1);
end

%create the family trees
Families.ProcessNewborns();

% try
%     backupCellFamilies = CellFamilies;
%     backupCellTracks = CellTracks;
%     backupHashedCells = HashedCells;
%     backupCellHulls = CellHulls;
%     backupCellFeatures = CellFeatures;
%     backupCosts = Costs;
%     backupGraphEdits = GraphEdits;
%     backupConnectedDist = ConnectedDist;
%     backupCellPhenotypes = CellPhenotypes;
%     
%     [iters totalTime] = Families.LinkFirstFrameTrees();
%     Error.LogAction('Completed Tree Inference', [iters totalTime],[]);
%     
%     backupCellFamilies = CellFamilies;
%     backupCellTracks = CellTracks;
%     backupHashedCells = HashedCells;
%     backupCellHulls = CellHulls;
%     backupCellFeatures = CellFeatures;
%     backupCosts = Costs;
%     backupGraphEdits = GraphEdits;
%     backupConnectedDist = ConnectedDist;
%     backupCellPhenotypes = CellPhenotypes;
%     
%     Segmentation.ResegRetrackLink();
%     
% catch excp
%     CellFamilies = backupCellFamilies;
%     CellTracks = backupCellTracks;
%     HashedCells = backupHashedCells;
%     CellHulls = backupCellHulls;
%     CellFeatures = backupCellFeatures;
%     Costs = backupCosts;
%     GraphEdits = backupGraphEdits;
%     ConnectedDist = backupConnectedDist;
%     CellPhenotypes = backupCellPhenotypes;
% end

end

function hullList = addToTrack(hull,hullList,objHulls)
%error checking
if(any(ismember(hullList,hull)) || objHulls(hull).inID ~= 0)
    %already part of a track
    return
end

Families.NewCellFamily(hull,objHulls(hull).t);
hullList = [hullList hull];

while(objHulls(hull).outID~=0)
    hull = objHulls(hull).outID;
    if(any(ismember(hullList,hull))),break,end
    if(any(ismember(hullList,objHulls(hull).inID)))
        Tracks.AddHullToTrack(hull,[],objHulls(hull).inID);
    else
        %this runs if there was an error in objHulls data structure
        Families.NewCellFamily(hull,objHulls(hull).t);
    end
    hullList = [hullList hull];
end
end

function connDist = updateConnectedDistance(fromObj, objHulls, connectedHulls)
    connDist = connectedHulls;
    
    if ( isempty(connectedHulls) )
        return;
    end
    
    zeroDist = find(connectedHulls(:,2) == 0);
    for i=1:length(zeroDist)
        toObj = objHulls(connectedHulls(zeroDist(i),1));
        isectDist = 1 - (length(intersect(fromObj.indPixels, toObj.indPixels)) / min(length(fromObj.indPixels), length( toObj.indPixels)));
        connDist(zeroDist(i),2) = isectDist;
    end
end
