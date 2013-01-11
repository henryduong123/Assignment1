function HematoTracker()
    global CONSTANTS CellHulls HashedCells ConnectedDist FluorData
    
    bKeep = (~[CellHulls.deleted]);
    CellHulls = CellHulls(bKeep);
    
    tmax = max([CellHulls.time]);
    HashedCells = cell(1,tmax);
    for t=1:tmax
        HashedCells{t} = struct('hullID',{}, 'trackID',{});
    end
    
    for i=1:length(CellHulls)
        HashedCells{CellHulls(i).time} = [HashedCells{CellHulls(i).time} struct('hullID',{i}, 'trackID',{0})];
    end
    
    fprintf(1,'Computing intersections with fluorescence images...');
    for t=1:tmax
        hulls = [HashedCells{t}(:).hullID];
        greenInd = FluorData(t).greenInd;
        for i=1:length(hulls)
            inter = intersect(CellHulls(hulls(i)).indexPixels, greenInd);
            if (isempty(inter))
                CellHulls(hulls(i)).greenInd = [];
            else
                CellHulls(hulls(i)).greenInd = greenInd;
            end
        end
    end
    fprintf(1, 'Done\n');
    
    ConnectedDist = [];
    fprintf(1,'Calculating Distances...');
    mexCCDistance(1:length(CellHulls),0);
    fprintf(1,'Done\n');
%     Tracker.BuildConnectedDistance(1:length(CellHulls), 0, 1);
    
    if ( ~exist('segmentationData','dir') )
        mkdir('segmentationData');
        pause(1);
    end
    
    Segmentation.RewriteSegData('segmentationData', CONSTANTS.datasetName);
    
    fnameIn=['.\segmentationData\SegObjs_' CONSTANTS.datasetName '.txt'];
    fnameOut=['.\segmentationData\Tracked_' CONSTANTS.datasetName '.txt'];
    
    fprintf(1,'Tracking...');
    system(['.\MTC.exe ' num2str(CONSTANTS.dMaxCenterOfMass) ' ' num2str(CONSTANTS.dMaxConnectComponentTracker) ' "' fnameIn '" "' fnameOut '" > out.txt']);
    fprintf('Done\n');
    
    fprintf(1,'Importing Tracking Results...');
    [objTracks gConnect] = Tracker.RereadTrackData('segmentationData', CONSTANTS.datasetName);
    fprintf('Done\n');
    
    fprintf('Finalizing Data...');
    Tracker.RebuildTrackingData(objTracks, gConnect);
    fprintf('Done\n');
end