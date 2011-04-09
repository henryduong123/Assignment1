function [gConnect, allPathsCosts] = constrainedBestPath(hullIdx, tStart, tEnd, constraints, hulls, hash, gConnect)
    scriptConstants
    global CONSTANTS
    
    windowSize = tEnd - tStart;
    
    cmin = Inf;
    allPaths = {};
    allPathsCosts = {};
    [path allPaths] = constrainedDFS(hullIdx, constraints, hulls, hash, tStart, tEnd, [], allPaths);
    
    trackIdx = hash{tStart}([hash{tStart}.hullID] == hullIdx).trackID;
    thHistory = [];
    for i=1:windowSize
        if ( tStart <= i )
            break;
        end
        
        prevStruct = hash{tStart-i}([hash{tStart-i}.trackID] == trackIdx);
        if ( isempty(prevStruct) )
            break;
        end
        
        hPrev = prevStruct.hullID;
        thHistory = [hPrev thHistory];
    end
    
    for i=1:length(allPaths)
        thPath=allPaths{i};
        if ( length(thPath) < 2 ),continue,end 

        thGlobal = [thHistory thPath];

        if 105==tStart
            dmax_cc=3*DMAX_CC;
            dmax_com=3*DMAX_COM;
        else
            dmax_cc=DMAX_CC;
            dmax_com=DMAX_COM;          
        end
        LocalCost = HullDist(hulls, thPath(1), thPath(2), dmax_cc, dmax_com);
        
        if ( ~isempty(thHistory) )
            LocalCost = 2*LocalCost + HullDist(hulls, thHistory(end),thPath(2),Inf,Inf);
        else
            LocalCost = 3*LocalCost;
        end
        
        if ( length(thPath) > 2 )
            LocalCost = LocalCost + HullDist(hulls, thPath(1),thPath(3),Inf,Inf);
        else
            LocalCost = 2*LocalCost;
        end

        % path cost - location
        locnHistory = [];
        for j=1:length(thHistory)
            pix = hulls(thGlobal(j)).indexPixels;
            [r c] = ind2sub(CONSTANTS.imageSize,pix);
            locnHistory = [locnHistory;r c];
        end
        pix = hulls(thPath(1)).indexPixels;
        [r c] = ind2sub(CONSTANTS.imageSize,pix);
        locnHistory = [locnHistory;r c];

        locnFuture=[];
        for j=1:length(thPath)
            pix = hulls(thPath(j)).indexPixels;
            [r c] = ind2sub(CONSTANTS.imageSize,pix);
            locnFuture = [locnFuture;r c];
        end

        locnCenter = mean(locnHistory, 1);    
        cLocation = mean(sqrt((locnFuture(:,1) - locnCenter(1)).^2 + (locnFuture(:,2) - locnCenter(2)).^2));
        if ( size(locnHistory,1) < windowSize )
            cLocation = cLocation * (windowSize - size(locnHistory,1));
        end
        % path cost - CV(brightness)
        pixels = vertcat(hulls(thGlobal).imagePixels);
        cIntensity = cov(pixels) / mean(pixels);

        %    cost=cIntensity+cVelocity+cLocation+5*LocalCost;
        cost = cIntensity + cLocation + 2*LocalCost;

        % length penalty
        if ( length(thGlobal) < 2*windowSize + 1 )
            LengthPenalty = (2*windowSize+1) - length(thGlobal);
            cost = cost*LengthPenalty*2;
        end

        if ( gConnect(thPath(1),thPath(2)) == 0 || cost < gConnect(thPath(1),thPath(2)) )
            gConnect(thPath(1),thPath(2)) = cost;
        end

        if ( cost < cmin )
            cmin = cost;
            imin = i;
        end

        allPathsCosts{end+1} = [cost allPaths{i}];
    end
end