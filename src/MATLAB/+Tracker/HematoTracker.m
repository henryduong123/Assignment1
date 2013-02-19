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

    fprintf(1,'Computing intersections with fluorescence images...');
    tic;
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
    fprintf(1, 'Done, %f sec\n', toc);
    
    fprintf(1,'Checking tracks for fluorescence...');
    tic;
    flTimes = find(HaveFluor);
    for i=1:length(CellTracks)
        times = CellTracks(i).startTime:CellTracks(i).endTime;
        CellTracks(i).markerTimes = intersect(times,flTimes);
        if(~isempty(CellTracks(i).markerTimes))
            wasGreen = 0;
            for j=1:size(CellTracks(i).markerTimes,2)
                hullID = Tracks.GetHullID(CellTracks(i).markerTimes(1,j),i);
                if (hullID <= 0)
                    CellTracks(i).markerTimes(2,j) = wasGreen;
                    continue;
                elseif (~isempty(CellHulls(hullID).greenInd))
                    inter = intersect(CellHulls(hullID).greenInd,CellHulls(hullID).indexPixels);
                    if (length(inter)>length(CellHulls(hullID).indexPixels)*0.3)
                        CellTracks(i).markerTimes(2,j) = 1;
                        wasGreen = 1;
                        continue;
                    end
                end
                CellTracks(i).markerTimes(2,j) = 0;
                wasGreen = 0;
            end
        end
    end
    fprintf(1, 'Done, %f sec\n', toc);

    
end