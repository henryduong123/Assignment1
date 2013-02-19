function AddHematoFluor()
    global CONSTANTS CellHulls HashedCells ConnectedDist FluorData CellTracks HaveFluor

    tmax = max([CellHulls.time]);

    fprintf(1, 'Clearing out old fluorescence indicators...');
    tic;
    for t=1:tmax
        hulls = [HashedCells{t}(:).hullID];
        for i=1:length(hulls)
            CellHulls(hulls(i)).greenInd = [];
        end
    end
    for i=1:length(CellTracks)
        CellTracks(i).markerTimes = {};
        CellTracks(i).fluorTimes = {};
    end
    fprintf(1, 'Done, %f sec\n', toc);
    
    fprintf(1,'Computing intersections with fluorescence images...');
    tic;
    for t=1:tmax
        if (t == 961)
            t = 961;
        end
        hulls = [HashedCells{t}(:).hullID];
        greenInd = FluorData(t).greenInd;
        for i=1:length(hulls)
            if (i == 22)
                i = 22;
            end
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
        if (i == 18075)
            i = 18075;
        end
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
        CellTracks(i).fluorTimes = CellTracks(i).markerTimes;
    end
    
    [bErr] = Editor.ReplayableEditAction(@Editor.AddHematoFluor, []);
    if ( bErr )
        return;
    end

    fprintf(1, 'Done, %f sec\n', toc);

end