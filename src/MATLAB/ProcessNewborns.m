%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
%     This file is part of LEVer.exe
%     (C) 2011 Andrew Cohen, Eric Wait and Mark Winter
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function ProcessNewborns(families, tFinal)
%This takes all the families with start times > 1 and attempts to attach
%that families' tracks to other families that start before said family


global CellFamilies CellTracks CellHulls HashedCells CONSTANTS GraphEdits Figures

% If unspecified start looking for children in frame 2
% if ( ~exist('tStart','var') )
%     tStart = 2;
% else
%     tStart = max(tStart, 2);
% end

if ( ~exist('families','var') )
    families = 1:length(CellFamilies);
end

if ( ~exist('tFinal','var') )
    tFinal = length(HashedCells);
end

tStart = 2;

rootHull = 0;
if ( isfield(Figures, 'tree') &&  Figures.tree.familyID>0 ...
        && Figures.tree.familyID<=length(CellFamilies))
    rootTrackID = CellFamilies(Figures.tree.familyID).rootTrackID;
    if ( ~isempty(rootTrackID) )
        rootHull = CellTracks(rootTrackID).hulls(1);
    end
end

costMatrix = GetCostMatrix();

size = length(families);
for i=1:size
    if ( isempty(CellFamilies(families(i)).startTime) )
        continue;
    end
    
    if ( CellFamilies(families(i)).startTime < tStart )
        continue;
    end
    
    %The root of the track to try to connect with another track
    childTrackID = CellFamilies(families(i)).rootTrackID;
    familyTimeFrame = CellFamilies(families(i)).endTime - CellFamilies(families(i)).startTime;

    %Get all the possible hulls that could have been connected
    childHullID = CellTracks(childTrackID).hulls(1);
    if(childHullID>length(costMatrix) || childHullID==0),continue,end
    parentHullCandidates = find(costMatrix(:,childHullID));

    % Don't consider deleted hulls as parents
    bDeleted = [CellHulls(parentHullCandidates).deleted];
    parentHullCandidates = parentHullCandidates(~bDeleted);
    
    if(isempty(parentHullCandidates)),continue,end
    if(~any(GraphEdits(parentHullCandidates,childHullID)) && CONSTANTS.minFamilyTimeFrame >= familyTimeFrame),continue,end

    %Get the costs of the possible connections
    parentCosts = costMatrix(parentHullCandidates,childHullID);
    bMitosisCost = true(1,nnz(parentCosts));
    
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
            bMitosisCost(j) = false;
        elseif(~isempty(CellTracks(parentTrackID).timeOfDeath))
            parentCosts(j) = Inf;
        else
            siblingHullIndex = CellHulls(childHullID).time - CellTracks(parentTrackID).startTime + 1;
            % ASSERT ( siblingHullIndex > 0 && <= length(hulls)
            sibling = CellTracks(parentTrackID).hulls(siblingHullIndex);
            parentCosts(j) = parentCosts(j) + SiblingDistance(childHullID,sibling);
        end
        if ( GraphEdits(parentHullCandidates(j),childHullID) > 0 )
            parentCosts(j) = costMatrix(parentHullCandidates,childHullID);
        end
    end

    %Pick the best candidate
    parentCosts = full(parentCosts);
    [minCost index] = min(parentCosts(find(parentCosts)));
    if(isinf(minCost)),continue,end
    
    % Do not allow reconnect of removed edges
    if ( GraphEdits(parentHullCandidates(index),childHullID) < 0 )
        continue;
    end
    
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
    
    % If the parent future is long enough create a mitosis, otherwise patch up track with parent
    if ( bMitosisCost(index) )
        connectTime = CellHulls(parentHullID).time+1;
        if( CONSTANTS.minParentHistoryTimeFrame < abs(CellTracks(childTrackID).startTime - CellTracks(parentTrackID).startTime)...
            || (GraphEdits(parentHullID,childHullID) > 0 && nnz(GraphEdits(parentHullID,:)) > 1) )
            ChangeTrackParent(parentTrackID,connectTime,childTrackID);
        end
    elseif ( isempty(CellTracks(parentTrackID).childrenTracks) )
        if ( CellTracks(childTrackID).startTime <= CellTracks(parentTrackID).endTime )
            RemoveFromTree(CellTracks(childTrackID).startTime, parentTrackID, 'no');
        end
        ChangeLabel(CellTracks(childTrackID).startTime, childTrackID, parentTrackID);
        RehashCellTracks(parentTrackID,CellTracks(parentTrackID).startTime);
    end
end

%trim the tree
% 
% for i=1:length(families)
%     if ( isempty(CellFamilies(families(i)).startTime) )
%         continue;
%     end
%     
%     if ( CellFamilies(families(i)).endTime < tFinal )
%         continue;
%     end
%     
%     removeTracks = [];
%     for j=1:length(CellFamilies(families(i)).tracks)
%         trackID = CellFamilies(families(i)).tracks(j);
%         if ( ~validBranch(trackID, tFinal) )
%             removeTracks = [removeTracks trackID];
%         end
%     end
%     
%     j = 1;
%     while( j <= length(removeTracks) )
%         siblingTrack = CellTracks(removeTracks(j)).siblingTrack;
%         parentTrack = CellTracks(removeTracks(j)).parentTrack;
%         if ( any(ismember(removeTracks, siblingTrack)) && ~any(ismember(removeTracks, parentTrack)) && ~checkEditedTrack(parentTrack) )
%             removeTracks = [removeTracks parentTrack];
%         end
%         j = j + 1;
%     end
%     
%     for j=1:length(removeTracks)
%         removeID = removeTracks(j);
%         
%         if ( isempty(CellTracks(removeID).startTime) )
%             continue;
%         end
%         
%         siblingTrack = CellTracks(removeTracks(j)).siblingTrack;
%         if ( any(ismember(removeTracks, siblingTrack)) )
%             [removeID mergeID] = findRemoveSibling(removeTracks(j), siblingTrack);
%         end
%         RemoveFromTree(CellTracks(removeID).startTime, removeID, 'yes');
%     end
% end

if ( rootHull > 0 )
    trackID = GetTrackID(rootHull);
    if ( ~isempty(trackID) )
        Figures.tree.familyID = CellTracks(trackID).familyID;
    end
end

end

function [removeID mergeID] = findRemoveSibling(trackID, siblingID)
    global CellTracks
    
    removeID = trackID;
    mergeID = siblingID;
    
    parentID = CellTracks(trackID).parentTrack;
    
    parentHull = CellTracks(parentID).hulls(end);
    hull = CellTracks(trackID).hulls(1);
    siblingHull = CellTracks(siblingID).hulls(1);
    
    if ( parentHull == 0 || hull == 0 || siblingHull == 0 )
        return;
    end
    
    costMatrix = GetCostMatrix();
    
    hullCost = costMatrix(parentHull,hull);
    siblingCost = costMatrix(parentHull,siblingHull);
    
    if ( hullCost < siblingCost )
        removeID = siblingID;
        mergeID = trackID;
    end
end

function bValid = validBranch(trackID, tFinal)
    global CellTracks
    
    bLeaf = isLeafBranch(trackID);
    bValid = (~bLeaf || (CellTracks(trackID).endTime >= tFinal) ...
        || (~isempty(CellTracks(trackID).phenotype) && (CellTracks(trackID).phenotype ~= 0)));
    
    if ( bLeaf && ~bValid )
        bValid = checkEditedTrack(trackID);
    end
end

function bEdited = checkEditedTrack(trackID)
    global CellTracks GraphEdits
    
    bEdited = 0;
    
    parentID = CellTracks(trackID).parentTrack;
    if ( isempty(parentID) )
        return;
    end
    
    parentHull = CellTracks(parentID).hulls(end);
	hull = CellTracks(trackID).hulls(1);
    
    if ( GraphEdits(parentHull,hull) > 0 )
        bEdited = 1;
    end
end

function bLeaf = isLeafBranch(trackID)
    global CellTracks
    
    bLeaf = (isempty(CellTracks(trackID).childrenTracks) && ~isempty(CellTracks(trackID).parentTrack));
end

