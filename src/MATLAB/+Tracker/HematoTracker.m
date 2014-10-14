function HematoTracker()
    global CONSTANTS CellHulls HashedCells ConnectedDist FluorData CellTracks HaveFluor
    
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
    
    ConnectedDist = [];
    fprintf(1,'Calculating Distances...');
    Tracker.BuildConnectedDistance(1:length(CellHulls), 0, 1);
    fprintf(1,'Done\n');
    
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

    if (~isempty(FluorData))
        fprintf(1,'Computing intersections with fluorescence images...');
        for t=1:tmax
            if isempty(HashedCells{t})
                hulls = [];
            else
                hulls = [HashedCells{t}(:).hullID];
            end
            greenInd = FluorData(t).greenInd;
            for i=1:length(hulls)
                inter = intersect(CellHulls(hulls(i)).indexPixels, greenInd);
                if (isempty(inter))
                    CellHulls(hulls(i)).greenInd = [];
                else
                    CellHulls(hulls(i)).greenInd = 1;
                end
            end
        end
        fprintf('Done\n');
        
        Tracker.AddHematoFluor(0);
    end
    
end
