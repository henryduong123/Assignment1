function PropagateChanges(trackHulls, editedHulls)
    global CellHulls HashedCells
    
    tStart = min([CellHulls(editedHulls).time]);
    tEnd = length(HashedCells);
    
    % Get initial changehulls to update
    trackHulls = intersect([HashedCells{tStart}.hullID],trackHulls);
    
    for t=tStart:tEnd
        if ( isempty(trackHulls) )
            Progressbar(1);
            return;
        end

        if ( t >= length(HashedCells) )
            Progressbar(1);
            return;
        end
        
        Progressbar((t-tStart)/(tEnd-tStart));
        
        checkHulls = [HashedCells{t}.hullID];
        checkTracks = [HashedCells{t}.trackID];
        nextHulls = [HashedCells{t+1}.hullID];

        UpdateTrackingCosts(t, trackHulls, nextHulls);

        [costMatrix bOutTracked bInTracked] = GetCostSubmatrix(checkHulls, nextHulls);
        checkHulls = checkHulls(bOutTracked);
        checkTracks = checkTracks(bOutTracked);
        nextHulls = nextHulls(bInTracked);
        
        % Figure out which hulls are assigned to tracks we allow to split
        bPastEdit = (t >= [CellHulls(editedHulls).time]);
        followTracks = GetTrackID(editedHulls(bPastEdit));
        
        bFollowTracks = ismember(checkTracks, followTracks);
        followTracks = checkTracks(bFollowTracks);
        followHulls = checkHulls(bFollowTracks);
        
        % Stop if none of the original split tracks are still around
        if ( isempty(followTracks) )
            ReassignTracks(t+1, costMatrix, checkHulls, nextHulls, [], 1);
            Progressbar(1);
            return;
        end

        allNewHulls = [];
        splits = findSplits(costMatrix, checkHulls, nextHulls);
        for i=1:length(splits)
            splitHulls = checkHulls(splits{i});
            bFollowSplit = ismember(splitHulls, followHulls);
            if ( ~any(bFollowSplit) )
                continue;
            end

%             if ( ~all(checkTrackLengths(splitHulls(~bFollowSplit),5)) )
%                 continue;
%             end

            % Try to split
            [newHulls oldCOM] = splitNextFrame(nextHulls(i), length(splitHulls));
            if ( isempty(newHulls) )
                continue;
            end
            
            TrackThroughSplit(t+1, newHulls, oldCOM);
            allNewHulls = [allNewHulls newHulls];
        end
        
        nextHulls = [HashedCells{t+1}.hullID];
        [costMatrix bOutTracked bInTracked] = GetCostSubmatrix(checkHulls, nextHulls);
        
        extendHulls = checkHulls(bOutTracked);
        affectedHulls = nextHulls(bInTracked);

        trackHulls = ReassignTracks(t+1, costMatrix, extendHulls, affectedHulls, allNewHulls);
    end
    
    Progressbar(1);
end

function [newHullIDs oldCOM] = splitNextFrame(hullID, k)
    global CellHulls

    newHullIDs = [];
    oldCOM = CellHulls(hullID).centerOfMass;
%     oldTracks = [HashedCells{CellHulls(hull).time}.trackID];

    newHulls = ResegmentHull(CellHulls(hullID), k);
    if ( isempty(newHulls) )
        return;
    end

    % Just arbitrarily assign clone's hull for now
    CellHulls(hullID) = newHulls(1);
    newHullIDs = hullID;

    % Other hulls are just added off the clone
    newFamilyIDs = [];
    for i=2:length(newHulls)
        CellHulls(end+1) = newHulls(i);
        newFamilyIDs = [newFamilyIDs NewCellFamily(length(CellHulls), newHulls(i).time)];
        newHullIDs = [newHullIDs length(CellHulls)];
    end
end

function bFullLength = checkTrackLengths(hulls, minlength)
    global CellHulls CellTracks
    
    bFullLength = false(size(hulls));
    
    for i=1:length(hulls)
        t = CellHulls(hulls(i)).time;
        trackID = GetTrackID(hulls(i),t);
        
        hasht = t - CellTracks(trackID).startTime + 1;
        if ( hasht < minlength )
            continue;
        end
        
        hashmin = (t-minlength+1) - CellTracks(trackID).startTime + 1;
        if ( ~all(CellTracks(trackID).hulls(hashmin:hasht) > 0) )
            continue;
        end
        
        bFullLength(i) = 1;
    end
end

function splits = findSplits(costMatrix, checkHulls, nextHulls)
    global ConnectedDist

    [minIn,bestIn] = min(costMatrix,[],1);
    [minOut,bestOut] =  min(costMatrix,[],2);
    
    splits = cell(1,size(costMatrix,2));
    
    bestOut = bestOut';
    for i=1:size(costMatrix,2)
        wants=find(bestOut == i);
        
        if ( length(wants) <= 1 )
            continue;
        end
        
        % Only split using overlapping cells
        bValidWants = true(size(wants));
        for k=1:length(wants)
            if ( isempty(ConnectedDist{checkHulls(wants(k))}) )
                continue;
            end
            
            ccidx = find(ConnectedDist{checkHulls(wants(k))}(:,1) == nextHulls(i));
            if ( isempty(ccidx) || ConnectedDist{checkHulls(wants(k))}(ccidx,2) >= 1.0 )
                bValidWants(k) = 0;
            end
        end
        
        wants = wants(bValidWants);
        
        if ( length(wants) <= 1 )
            continue;
        end
        
        splits{i} = wants;
    end
end
