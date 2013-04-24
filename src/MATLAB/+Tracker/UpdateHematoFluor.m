function UpdateHematoFluor(t)
    global CellHulls HashedCells FluorData CellTracks HaveFluor

    hulls = [HashedCells{t}(:).hullID];
    for i=1:length(hulls)
        CellHulls(hulls(i)).greenInd = [];
    end
    
%     for i=1:length(CellTracks)
%         CellTracks(i).markerTimes = {};
%     end

    hulls = [HashedCells{t}(:).hullID];
    greenInd = FluorData(t).greenInd;
    for i=1:length(hulls)
        inter = intersect(CellHulls(hulls(i)).indexPixels, greenInd);
        if (isempty(inter))
            CellHulls(hulls(i)).greenInd = [];
        else
            CellHulls(hulls(i)).greenInd = 1;
        end
    end
    
    flTimes = find(HaveFluor);
    for i=1:length(CellTracks)
        if (i == 18386)
            i = 18386;
        end
        if (i == 23505)
            i = 23505;
        end
        if (isempty(CellTracks(i).startTime) || isempty(CellTracks(i).endTime))
            continue;
        end
        if (t < CellTracks(i).startTime || t > CellTracks(i).endTime)
            continue;
        end
        times = CellTracks(i).startTime:CellTracks(i).endTime;
        CellTracks(i).markerTimes = intersect(times,flTimes);
        if(~isempty(CellTracks(i).markerTimes))
            wasGreen = 0;
            for j=1:size(CellTracks(i).markerTimes,2)
                t2 = CellTracks(i).markerTimes(1,j);
                hullID = Tracks.GetHullID(t2,i);
                if (hullID <= 0)
                    CellTracks(i).markerTimes(2,j) = wasGreen;
                    continue;
                elseif (~isempty(CellHulls(hullID).greenInd))
                    inter = intersect(FluorData(t2).greenInd,CellHulls(hullID).indexPixels);
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
end