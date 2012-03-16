function ExternalRetrack()
    global CONSTANTS CellHulls HashedCells CellFeatures ConnectedDist
    
    bKeep = (~[CellHulls.deleted]);
    CellHulls = CellHulls(bKeep);
    
    segtimes = [CellHulls.time];
    
    [srtseg srtidx] = sort(segtimes);
    [dump idxmap] = sort(srtidx);
    
    CellHulls = CellHulls(srtidx);
    CellFeatures = CellFeatures(srtidx);
    
%     newConnectedDist = ConnectedDist(srtidx);
%     for i=1:length(newConnectedDist)
%         if ( isempty(newConnectedDist{i}) )
%             continue;
%         end
%         
%         newConnectedDist{i}(:,1) = idxmap(newConnectedDist{i}(:,1))';
%     end
    
    tmax = max([CellHulls.time]);
    HashedCells = cell(1,tmax);
    for i=1:length(CellHulls)
        HashedCells{CellHulls(i).time} = [HashedCells{CellHulls(i).time} struct('hullID',{i}, 'trackID',{0})];
    end
    
    ConnectedDist = [];
    BuildConnectedDistance(1:length(CellHulls), 0, 1);
    
    RewriteSegData(CONSTANTS.datasetName);
    
    fnameIn=['.\segmentationData\SegObjs_' CONSTANTS.datasetName '.txt'];
    fnameOut=['.\segmentationData\Tracked_' CONSTANTS.datasetName '.txt'];
    tic
    fprintf(1,'Tracking...');
    system(['.\MTC.exe "' fnameIn '" "' fnameOut '" > out.txt']);
    fprintf('Done\n');
    tTrack=toc;
    
    [objTracks gConnect oldHashedHulls] = RereadTrackData(CONSTANTS.datasetName);
    
    fprintf('Finalizing Data...');
    RebuildTrackingData(objTracks, gConnect);
    fprintf('Done\n');
end