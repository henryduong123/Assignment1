function newHulls = SplitDeterministic(hull, k, checkHullIDs)
    global CONSTANTS CellHulls
    
    newHulls = [];
    
    hullTimes = unique([CellHulls(checkHullIDs).time]);
    if ( length(hullTimes) > 1 )
        newHulls = Segmentation.ResegmentHull(hull, k);
        return;
    end
    
    oldMeans = zeros(k,2);
    for i=1:length(checkHullIDs)
        [r c] = ind2sub(CONSTANTS.imageSize, CellHulls(checkHullIDs(i)).indexPixels);
        oldMeans(i,:) = mean([c r],1);
    end
    
    if ( length(hull.indexPixels) > 2 )
        return;
    end
    
    [r c] = ind2sub(CONSTANTS.imageSize, hull.indexPixels);
    if ( strcmpi(CONSTANTS.cellType,'Adult') )
        % Cheat and initially cluster about equiprobably
        com = mean([c r],1);
        oldCom = mean(oldMeans,1);
        deltaCom = com - oldCom;
        
        distSq = zeros(length(r), k);
%         startVar = ones(k,1);
        for i=1:length(checkHullIDs)
            oldMeans(i,:) = oldMeans(i,:) + deltaCom;
%             dcomSq(i) = (com(1)-oldMeans(i,1)).^2 + (com(2)-oldMeans(i,2)).^2;
            
            distSq(:,i) = ((c-oldMeans(i,1)).^2 + (r-oldMeans(i,2)).^2);
        end
        
        [minDist minIdx] = min(distSq,[],2);
        gmoptions = statset('Display','off', 'MaxIter',400);
        obj = gmdistribution.fit([c,r], k, 'Start',minIdx, 'Regularize',0.5 , 'Options',gmoptions);
        kIdx = cluster(obj, [c,r]);
    elseif ( strcmpi(CONSTANTS.cellType,'Hemato') )
        [kIdx centers] = kmeans([c,r], k, 'start',oldMeans, 'EmptyAction','drop');
    else
        [kIdx centers] = kmeans([c,r], k, 'start',oldMeans, 'EmptyAction','drop');
    end
    
    if ( any(isnan(kIdx)) )
        return;
    end

    connComps = cell(1,k);

    nh = Helper.MakeEmptyStruct(CellHulls);
    for i=1:k
        bIdxPix = (kIdx == i);

        hx = c(bIdxPix);
        hy = r(bIdxPix);

        % If any sub-object is less than 15 pixels then cannot split this
        % hull
        if ( nnz(bIdxPix) < 15 )
            newHulls = [];
            return;
        end

        connComps{i} = hull.indexPixels(bIdxPix);

        nh.indexPixels = hull.indexPixels(bIdxPix);
        nh.imagePixels = hull.imagePixels(bIdxPix);
        nh.centerOfMass = mean([hy hx]);
        nh.time = hull.time;

        try
            chIdx = convhull(hx, hy);
        catch excp
            newHulls = [];
            return;
        end

        nh.points = [hx(chIdx) hy(chIdx)];

        newHulls = [newHulls nh];
    end

    % Define an ordering on the hulls selected, COM is unique per component so
    % this gives a deterministic ordering to the components
    [sortCOM, sortIdx] = sortrows(vertcat(newHulls.centerOfMass));
    newHulls = newHulls(sortIdx);
    connComps = connComps(sortIdx);
    
end
