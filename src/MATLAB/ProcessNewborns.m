function ProcessNewborns(families)
%This takes all the families with start times > 1 and attempts to attach
%that families' tracks to other families that start before said family

%--Eric Wait

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
        if(childHullID>length(Costs) || childHullID==0),continue,end
        parentHullCandidates = find(Costs(:,childHullID));
        
        % Don't consider deleted hulls as parents
        bDeleted = [CellHulls(parentHullCandidates).deleted];
        parentHullCandidates = parentHullCandidates(~bDeleted);
        
        if(isempty(parentHullCandidates)),continue,end
        
        %Get the costs of the possible connections
        parentCosts = Costs(parentHullCandidates,childHullID);
        
        %Massage the costs a bit
        for j=1:length(parentHullCandidates)
            %Get the length of time that the parentCandidate exists
            parentTrackID = GetTrackID(parentHullCandidates(j));
            if(isempty(parentTrackID)),continue,end
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
                siblingHullIndex = CellHulls(childHullID).time - CellTracks(parentTrackID).startTime + 1;
                % ASSERT ( siblingHullIndex > 0 && <= length(hulls)
                sibling = CellTracks(parentTrackID).hulls(siblingHullIndex);
                parentCosts(j) = parentCosts(j) + SiblingDistance(childHullID,sibling);
            end
        end
        
        %Pick the best candidate
        parentCosts = full(parentCosts);
        [minCost index] = min(parentCosts(find(parentCosts)));
        if(isinf(minCost)),continue,end
        parentHullID = parentHullCandidates(index);
        
        %Make the connections
        parentTrackID = GetTrackID(parentHullID);
        if(isempty(parentTrackID))
            try
                ErrorHandeling(['GetTrackID(' num2str(parentHullID) ') -- while in ProcessNewborns'],dbstack);
                return
            catch errorMessage2
                fprintf('%s',errorMessage2);
                return
            end
        end
        connectTime = CellHulls(parentHullID).time+1;
        if(CONSTANTS.minParentHistoryTimeFrame < abs(CellTracks(childTrackID).startTime - CellTracks(parentTrackID).startTime))
            ChangeTrackParent(parentTrackID,connectTime,childTrackID);
        end
    end
end
end
