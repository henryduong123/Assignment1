% Go through all frames attempting to make the segmentation consistent with
% the edited lineages for cell trees in families.  We encourage consistency
% by attempting to split segmentations or utilize non-family segmentations
function [oldHulls oldIdx] = ResegmentEditedFamilies(families, hullCheckRadiusSq)
    global CONSTANTS CellHulls HashedCells CellFamilies CellTracks

    oldHulls = [];
    oldIdx = [];
    
    familyTracks = [];
    for i=1:length(families)
        familyTracks = union(familyTracks, CellFamilies(families(i)).tracks);
    end
    
    trackStarts = [CellTracks(familyTracks).startTime];
    trackEnds = [CellTracks(familyTracks).endTime];
    
    for t=1:length(HashedCells)
        bInTrack = ((t >= trackStarts) & (t <= trackEnds));
        
        if ( ~any(bInTrack) )
            continue;
        end
        
        checkFamTracks = familyTracks(bInTrack);
        frameTracks = [HashedCells{t}.trackID];
        
%         bInFamily = ismember(frameTracks, checkFamTracks);
        missSegTracks = setdiff(checkFamTracks, frameTracks);
        
        if ( isempty(missSegTracks) )
            continue;
        end
        
        fprintf('Processing frame t=%d: ', t);
        timer = tic();
        
%         frameHulls = [HashedCells{t}.hullID];
        lastHulls = findLastSegmentation(t, missSegTracks);
%         hullDistSq = calcHullDistances(lastHulls, frameHulls);
%         
%         bInRadius = (hullDistSq <= hullCheckRadiusSq);
        %maxSplit = sum(1,bInRadius) + bInFamily;
        
        fprintf('missed=%d, ', length(missSegTracks));
        
        for i=1:length(missSegTracks)
            % Update these in case we've added hulls/tracks
            frameTracks = [HashedCells{t}.trackID];
            bInFamily = ismember(frameTracks, checkFamTracks);
            
            frameHulls = [HashedCells{t}.hullID];
            hullDistSq = calcHullDistances(lastHulls, frameHulls);
            bInRadius = (hullDistSq <= hullCheckRadiusSq);
            
            maxSplit = bInRadius(i,:) + (bInRadius(i,:) & bInFamily);
            if ( max(maxSplit) < 1 )
                continue;
            end
            
            [newHulls newHash splitInfo] = createSplitHulls(t, maxSplit, frameHulls);
            [newHulls newHash hullsToTrack] = getHullsToTrack(t, frameTracks, missSegTracks(i), splitInfo, newHulls, newHash);
            % Don't track hulls outside radius
            avoidHulls = frameHulls(cellfun('isempty', splitInfo.splitLevels(1,:)));
            % Also don't track family hulls
            avoidHulls = union(avoidHulls, frameHulls(bInFamily));
            
            if ( isempty(hullsToTrack) )
                continue;
            end
            
            tmpgConnect = trackingCosts(hullsToTrack, t-1, avoidHulls, newHulls, newHash);
            
            nzCostIdx = find(tmpgConnect(hullsToTrack(1),:)>0);
            
            [mincost assignIdx] = min(tmpgConnect(hullsToTrack(1),nzCostIdx));
            if ( isempty(assignIdx) )
                continue;
            end
            
            assignIdx = nzCostIdx(assignIdx);
            
            bestIdx = find(splitInfo.hulls(:,1) == assignIdx);
            
            splitlevel = splitInfo.hulls(bestIdx,3);
            if ( splitlevel > 1 )
                % Assign a split
                parentIdx = splitInfo.hulls(bestIdx,2);
                infoIdx = find(frameHulls == parentIdx, 1, 'first');
                otherIdx = setdiff(splitInfo.splitLevels{splitlevel,infoIdx}, assignIdx);
                
                parentTrack = frameTracks(infoIdx);
                
                oldHulls = [oldHulls CellHulls(parentIdx)];
                
                CellHulls(parentIdx) = newHulls(assignIdx);
                CellHulls = [CellHulls newHulls(otherIdx)];
                
                oldIdx = [oldIdx; parentIdx length(oldHulls);length(CellHulls) length(oldHulls)];
                
                HashedCells{t}([HashedCells{t}.hullID] == parentIdx).trackID = missSegTracks(i);
                
                nhash = struct('hullID', length(CellHulls), 'trackID', parentTrack);
                HashedCells{t} = [HashedCells{t} nhash];
                
                AddHullToTrack(length(CellHulls), parentTrack);
                AddHullToTrack(parentIdx, missSegTracks(i));
            else
                % Assign to non-family hull
                parentIdx = splitInfo.hulls(bestIdx,2);
                infoIdx = find(frameHulls == parentIdx, 1, 'first');
                parentTrack = frameTracks(infoIdx);
                
                oldHulls = [oldHulls CellHulls(parentIdx)];
                oldIdx = [oldIdx; parentIdx length(oldHulls)];
                
                CellTracks(parentTrack).hulls(CellTracks(parentTrack).hulls == parentIdx) = 0;
                
                AddHullToTrack(parentIdx, missSegTracks(i));
            end
        end
        
        fprintf('%f seconds\n', toc(timer));
    end
end

function distSq = calcHullDistances(lastHulls, frameHulls)
    global CellHulls
    
    lastCOM = cat(1,CellHulls(lastHulls).centerOfMass);
    frameCOM = cat(1,CellHulls(frameHulls).centerOfMass);
    
    distSq = (lastCOM(:,1)*ones(1,length(frameHulls)) - ones(length(lastHulls),1)*frameCOM(:,1)').^2 + (lastCOM(:,2)*ones(1,length(frameHulls)) - ones(length(lastHulls),1)*frameCOM(:,2)').^2;
end

function lastIdx = findLastSegmentation(t, missedSegTracks)
    global CellTracks
    
    lastIdx = zeros(1,length(missedSegTracks));
    
    for i=1:length(missedSegTracks)
        tidx = t - CellTracks(missedSegTracks(i)).startTime + 1;
        lastIdx(i) = CellTracks(missedSegTracks(i)).hulls(find(CellTracks(missedSegTracks(i)).hulls(1:tidx), 1, 'last'));
    end
end

function [newHulls newHash hullsToTrack bMissedSeg] = getHullsToTrack(t, frameTracks, missSegTracks, splitInfo, newHulls, newHash)
    global HashedCells
    
    bPrevHulls = ismember([HashedCells{t-1}.trackID], missSegTracks);
    
    maxOcclusion = 3;
    i = 2;
    while( isempty(bPrevHulls) && i < maxOcclusion )
        bPrevHulls = ismember([HashedCells{t-i}.trackID], missSegTracks);
        i = i+1;
    end
    
    hullsToTrack = [HashedCells{t-1}(bPrevHulls).hullID];
    bMissedSeg = true(1,length(hullsToTrack));
    
    if ( isempty(hullsToTrack) )
        return;
    end
    
    if ( size(splitInfo.splitLevels,1) < 2 )
        return;
    end
    
    for i=1:length(splitInfo.splitLevels(2,:))
        if ( isempty(splitInfo.splitLevels{2,i}) )
            continue;
        end
        
        bPrevHull = ([HashedCells{t-1}.trackID] == frameTracks(i));
         
        if ( ~any(bPrevHull) )
            continue;
        end
        
        hullsToTrack = [hullsToTrack HashedCells{t-1}(bPrevHull).hullID];
        bMissedSeg = [bMissedSeg 0];
    end
end

function [newHulls newHash splitInfo] = createSplitHulls(t, maxSplit, frameHulls)
    global CellHulls HashedCells
    
    newHulls = CellHulls;
    newHash = HashedCells;
    
    splitInfo.splitLevels = cell(max(maxSplit),length(frameHulls));
    splitInfo.hulls = [];
    
    for i=1:length(frameHulls)
        for k=1:maxSplit(i)
            if ( k == 1 )
                splitInfo.splitLevels{k,i} = frameHulls(i);
                splitInfo.hulls = [splitInfo.hulls; frameHulls(i) frameHulls(i) k];
                continue;
            end
            
            splitHulls = splitCellHull(k, frameHulls(i));
            
            if ( isempty(splitHulls) )
                continue;
            end
            
            [newHulls newHash addedIdx] = addHulls(t, splitHulls, newHulls, newHash);
            
            splitInfo.splitLevels{k,i} = addedIdx;
            for j=1:length(addedIdx)
                splitInfo.hulls = [splitInfo.hulls; addedIdx(j) frameHulls(i) k];
            end
        end
    end
end

function [newHulls newHash addIdx] = addHulls(t, splitHulls, newHulls, newHash)
    addIdx = length(newHulls) + (1:length(splitHulls));
    
    hash = struct('hullID', addIdx, 'trackID', zeros(size(addIdx)));
    
    newHulls = [newHulls splitHulls];
    newHash{t} = [newHash{t} hash];
end

function splitHulls = splitCellHull(k, hullIdx)
    global CONSTANTS CellHulls
    
    splitHulls = [];
    
    [r c] = ind2sub(CONSTANTS.imageSize, CellHulls(hullIdx).indexPixels);
    oidx = kmeans([r c], int32(k), 'EmptyAction','drop', 'Replicates',5);
    if ( any(isnan(oidx)) )
        return;
    end
    
    nh = struct('time', [], 'points', [], 'centerOfMass', [], 'indexPixels', [], 'imagePixels', [], 'deleted', 0);
    for i=1:max(oidx)
        bSplit = (oidx == i);
        
        if ( nnz(bSplit) < 30 )
            splitHulls = [];
            return;
        end
        
        hx = c(bSplit);
        hy = r(bSplit);
        
        nh.time = CellHulls(hullIdx).time;
        nh.indexPixels = CellHulls(hullIdx).indexPixels(bSplit);
        nh.imagePixels = CellHulls(hullIdx).imagePixels(bSplit);
        nh.centerOfMass = mean([hy hx]);
        
        try
            chIdx = convhull(hx, hy);
        catch
            splitHulls = [];
            return;
        end
        
        nh.points = [hx(chIdx) hy(chIdx)];
        
        splitHulls = [splitHulls nh];
    end
end

