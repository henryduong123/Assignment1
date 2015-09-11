function newHulls = SplitDeterministic(hull, k, checkHullIDs)
    global CONSTANTS CellHulls
    
    newHulls = [];
    
    hullTimes = unique([CellHulls(checkHullIDs).time]);
    if ( length(hullTimes) > 1 )
        newHulls = Segmentation.ResegmentHull(hull, k);
        return;
    end
    
    oldMeans = zeros(k, Helper.GetNumberOfDimensions());
    for i=1:length(checkHullIDs)
        oldCoord = Helper.IndexToCoord(CONSTANTS.imageSize, CellHulls(checkHullIDs(i)).indexPixels);
        oldCoord(:,[1 2]) = oldCoord(:,[2 1]);
        oldMeans(i,:) = mean(oldCoord,1);
    end
    
    if ( length(hull.indexPixels) < 2 )
        return;
    end
    
    coordinates = Helper.IndexToCoord(CONSTANTS.imageSize, hull.indexPixels);
    coordinates(:,[1 2]) = coordinates(:,[2 1]);
    
    typeParams = Load.GetCellTypeParameters(CONSTANTS.cellType);
    if ( typeParams.splitParams.useGMM )
        kIdx = gmmCluster(coordinates, k, oldMeans);
    else
        kIdx = kmeans(coordinates, k, 'start',oldMeans, 'EmptyAction','drop');
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
        nh.centerOfMass = mean([hy hx]);
        nh.time = hull.time;

        chIdx = Helper.ConvexHull(hx,hy);
        if ( isempty(chIdx) )
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

function kIdx = gmmCluster(X, k, oldMeans)
    % Cheat and initially cluster about equiprobably
    com = mean(X,1);
    oldCom = mean(oldMeans,1);
    deltaCom = com - oldCom;

    distSq = zeros(size(X,1), k);
%     startVar = ones(k,1);
    for i=1:size(oldMeans,1)
        oldMeans(i,:) = oldMeans(i,:) + deltaCom;
%         dcomSq(i) = (com(1)-oldMeans(i,1)).^2 + (com(2)-oldMeans(i,2)).^2;

        distSq(:,i) = ((X(:,1)-oldMeans(i,1)).^2 + (X(:,2)-oldMeans(i,2)).^2);
    end

    [minDist minIdx] = min(distSq,[],2);
    gmoptions = statset('Display','off', 'MaxIter',400);
    obj = Helper.fitGMM(X, k, 'Start',minIdx, 'Regularize',0.5 , 'Options',gmoptions);
    kIdx = cluster(obj, X);
end

