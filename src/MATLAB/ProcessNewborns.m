function ProcessNewborns(families)
%This takes all the families with start times > 1 and attempts to attach
%that families' tracks to other families that start before said family

global CellFamilies CellTracks CellHulls Costs CONSTANTS  
size = length(families);
for i=1:size
    if(1 < CellFamilies(families(i)).startTime)
        %The root of the track to try to connect with another track
        childTrackID = CellFamilies(families(i)).rootTrackID;
        familyTimeFrame = CellFamilies(families(i)).endTime - CellFamilies(families(i)).startTime;
        if(CONSTANTS.minFamilyTimeFrame >= familyTimeFrame),continue,end
        
        %Get all the possible hulls that could have been connected
        childHullID = CellTracks(childTrackID).hulls(1);
        parentHullCandidates = find(Costs(:,childHullID));
        if(isempty(parentHullCandidates)),continue,end
        
        %Get the costs of the possible connections
        parentCosts = Costs(parentHullCandidates,childHullID);
        
        %Massage the costs a bit
        for j=1:length(parentHullCandidates)
            %Get the length of time that the parentCandidate exists
            parentTrackID = GetTrackID(parentHullCandidates(j));
            parentTrackTimeFrame = CellTracks(parentTrackID).endTime - CellTracks(parentTrackID).startTime;
            
            %Change the cost of the candidates
            if(CONSTANTS.minParentCandidateTimeFrame >= parentTrackTimeFrame)
                parentCosts(j) = Inf;
            elseif(CONSTANTS.maxFrameDifference < abs(CellTracks(childTrackID).startTime - CellHulls(parentHullCandidates(j)).time))
                parentCosts(j) = Inf;
            elseif(CONSTANTS.minParentFuture >= CellTracks(parentTrackID).endTime - CellHulls(parentHullCandidates(j)).time)
                parentCosts(j) = Inf;
            elseif(~isempty(CellTracks(parentTrackID).timeOfDeath))
                parentCosts(j) = Inf;
            else
                parentCosts(j) = parentCosts(j) + SiblingDistance(childHullID,parentHullCandidates(j));
            end
        end
        
        %Pick the best candidate
        parentCosts = full(parentCosts);
        [minCost index] = min(parentCosts(find(parentCosts)));
        if(isinf(minCost)),continue,end
        parentHullID = parentHullCandidates(index);
        
        %Make the connections
        parentTrackID = GetTrackID(parentHullID);
        connectTime = CellHulls(parentHullID).time;
        if(CONSTANTS.minParentHistoryTimeFrame < abs(CellTracks(childTrackID).startTime - CellTracks(parentTrackID).startTime))
            ChangeTrackParent(parentTrackID,connectTime,childTrackID);
        end
    end
end
end
