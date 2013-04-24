function AddHematoFluor(addToHistory)
    global CONSTANTS CellHulls HashedCells ConnectedDist FluorData CellTracks HaveFluor

    tmax = max([CellHulls.time]);

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
                CellHulls(hulls(i)).greenInd = 1;
            end
        end
    end
    
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
                t = CellTracks(i).markerTimes(1,j);
                hullID = Tracks.GetHullID(t,i);
                if (hullID <= 0)
                    CellTracks(i).markerTimes(2,j) = wasGreen;
                    continue;
                elseif (~isempty(CellHulls(hullID).greenInd))
                    inter = intersect(FluorData(t).greenInd,CellHulls(hullID).indexPixels);
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
 
    if (addToHistory)
        [bErr] = Editor.ReplayableEditAction(@Editor.AddHematoFluor, []);
        if ( bErr )
            return;
        end
    end

end