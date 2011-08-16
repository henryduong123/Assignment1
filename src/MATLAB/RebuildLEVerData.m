
% RebuildLEVerData can be used to attempt to rebuild CellTracks and
% CellFamily structures when they are corrupted. This function uses the
% Costs and GraphEdits sparse arrays
function RebuildLEVerData()
    global CellHulls HashedCells CellTracks CellFamilies
    
    tEnd = max([CellHulls.time]);
    
    CellTracks = [];
    CellFamilies = [];
    
    bAssign = sparse([],[],[],length(CellHulls),length(CellHulls),round(0.1*length(CellHulls)));
    
    %startHulls = find(~[CellHulls.deleted] & ([CellHulls.time] == 1));
    trackHulls = find(arrayfun(@(x)((~x.deleted) && (x.time == 1)), CellHulls));
    if ( isempty(trackHulls) )
        error('RebuildLEVerData - No segmentations in the first frame.');
    end
    
    cellTimes = [CellHulls.time];
    [tlist,cellIdx] = sort(cellTimes);
    
    HashedCells = cell(1,max(tlist));
    
    for i=1:length(tlist)
        HashedCells{tlist(i)} = [HashedCells{tlist(i)} struct('hullID',{cellIdx(i)},'trackID',{0},'editedFlag',{0})];
    end
    
    for i=1:length(trackHulls)
        InitializeTrack(trackHulls(i));
    end
    
    maxOcclSkip = 1;
    missedHulls = [];
    for t=1:(tEnd-1)
        fromHulls = [HashedCells{t}.hullID];
        toHulls = [HashedCells{t+1}.hullID];
        
        missedHulls([CellHulls(missedHulls).time] < t-maxOcclSkip) = [];
        fromHulls = [fromHulls missedHulls];
        
        [trackHulls,nextHulls] = addEditedHulls(fromHulls,toHulls);
        
        [assignedTrackHulls, assignedNextHulls] = assignToTracks(trackHulls, nextHulls);
        
        bAssign(assignedTrackHulls,assignedNextHulls) = 1;
        
        allAssignedToHulls = find(any(bAssign,1));
        newTrackHulls = setdiff(nextHulls, allAssignedToHulls);
        
        missedHulls = union(missedHulls,setdiff(trackHulls,assignedTrackHulls));
        
        for i=1:length(newTrackHulls)
            InitializeTrack(newTrackHulls(i));
        end
    end
    
    ProcessNewborns();
end

function [trackHulls,nextHulls] = addEditedHulls(fromHulls, toHulls)
    global GraphEdits CellHulls
    
    nextHulls = toHulls;
    trackHulls = fromHulls;
    
    if ( isempty(toHulls) )
        return;
    end
    
    needTrackHulls = find(any(GraphEdits(:,toHulls) == 1,2));
    needNextHulls = find(any(GraphEdits(fromHulls,:) == 1,1));
    
	trackHulls = union(trackHulls,needTrackHulls);
    nextHulls = union(nextHulls,needNextHulls);
    
    bDeleted = find([CellHulls(trackHulls).deleted]);
    trackHulls(bDeleted)=[];
    
    bDeleted = find([CellHulls(nextHulls).deleted]);
    nextHulls(bDeleted)=[];
end

function [assignedFromHulls,assignedToHulls] = assignToTracks(fromHulls, toHulls)

    assignedFromHulls = [];
    assignedToHulls = [];

    [costMatrix, bFromHulls, bToHulls] = GetCostSubmatrix(fromHulls, toHulls);
    
    fromHulls = fromHulls(bFromHulls);
    toHulls = toHulls(bToHulls);
    
    [minInCosts,bestIncoming] = min(costMatrix,[],1);
    [minOutCosts,bestOutgoing] = min(costMatrix,[],2);
    
    bestOutgoing  = bestOutgoing';
    bMatchedCol = false(size(bestIncoming));
    bMatched = (bestIncoming(bestOutgoing) == (1:length(bestOutgoing)));
    bMatchedCol(bestOutgoing(bMatched)) = 1;
    
    matchedIdx = find(bMatched);
    
    for i=1:length(matchedIdx)
        fromHullID = fromHulls(matchedIdx(i));
        toHullID = toHulls(bestOutgoing(matchedIdx(i)));
        
        trackID = GetTrackID(fromHullID);
        AddHullToTrack(toHullID,trackID);
        
        assignedFromHulls = [assignedFromHulls fromHullID];
        assignedToHulls = [assignedToHulls toHullID];
    end
end

function trackID = InitializeTrack(hullID)
    global CellHulls CellFamilies
    
    famID = NewCellFamily(hullID, CellHulls(hullID).time);
    trackID = CellFamilies(famID).rootTrackID;
end

