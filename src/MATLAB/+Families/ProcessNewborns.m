% ProcessNewborns(families)
% This takes all the families with start times > 1 and attempts to attach
% that families' tracks to other families that start before said family

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
%     Copyright 2011 Andrew Cohen, Eric Wait and Mark Winter
%
%     This file is part of LEVer - the tool for stem cell lineaging. See
%     https://pantherfile.uwm.edu/cohena/www/LEVer.html for details
% 
%     LEVer is free software: you can redistribute it and/or modify
%     it under the terms of the GNU General Public License as published by
%     the Free Software Foundation, either version 3 of the License, or
%     (at your option) any later version.
% 
%     LEVer is distributed in the hope that it will be useful,
%     but WITHOUT ANY WARRANTY; without even the implied warranty of
%     MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
%     GNU General Public License for more details.
% 
%     You should have received a copy of the GNU General Public License
%     along with LEVer in file "gnu gpl v3.txt".  If not, see 
%     <http://www.gnu.org/licenses/>.
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function ProcessNewborns(families)

global CellFamilies CellTracks CellHulls CONSTANTS GraphEdits Figures

if ( ~exist('families','var') )
    families = 1:length(CellFamilies);
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

Tracker.PatchMatchedTracks();

% %Remove any newly created parasite tracks from tree
% for i=1:length(families)
%     familyID = families(i);
%     for j=1:length(CellFamilies(familyID).tracks)
%         trackID = CellFamilies(familyID).tracks(j);
%         if ( Tracker.GetTrackSegScore(trackID) >= CONSTANTS.minTrackScore || isempty(CellTracks(trackID).parentTrack) )
%             continue;
%         end
%         
%         parentHullID = Tracks.GetHullID(CellTracks(trackID).startTime-1, CellTracks(trackID).parentTrack);
%         childHullID = Tracks.GetHullID(CellTracks(trackID).startTime, trackID);
%         
%         if ( isempty(parentHullID) || GraphEdits(parentHullID,childHullID) > 0 )
%             continue;
%         end
%         
%         if (~isempty(CellTracks(trackID).childrenTracks))
%             Families.RemoveFromTree(CellTracks(trackID).childrenTracks(1));
%         end
% 
%         Families.RemoveMitosis(trackID);
%     end
% end

costMatrix = Tracker.GetCostMatrix();

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
    
    childScore = Tracker.GetTrackSegScore(childTrackID);
    if ( childScore < CONSTANTS.minTrackScore )
        continue
    end
    
    %Massage the costs a bit
    for j=1:length(parentHullCandidates)
        %Get the length of time that the parentCandidate exists
        parentTrackID = Hulls.GetTrackID(parentHullCandidates(j));
        if(isempty(parentTrackID)),continue,end
        parentTrackTimeFrame = CellTracks(parentTrackID).endTime - CellTracks(parentTrackID).startTime;
        
        parentScore = Tracker.GetTrackSegScore(parentTrackID);

        %Change the cost of the candidates
        if(CONSTANTS.minParentCandidateTimeFrame >= parentTrackTimeFrame)
            parentCosts(j) = Inf;
        elseif(CONSTANTS.maxFrameDifference < abs(CellTracks(childTrackID).startTime - CellHulls(parentHullCandidates(j)).time))
            parentCosts(j) = Inf;
        elseif(CONSTANTS.minParentFuture >= CellTracks(parentTrackID).endTime - CellHulls(parentHullCandidates(j)).time)
            parentCosts(j) = Inf;
        elseif(~isempty(Tracks.GetTimeOfDeath(parentTrackID)))
            parentCosts(j) = Inf;
        elseif ( parentScore < CONSTANTS.minTrackScore )
            parentCosts(j) = Inf;
        else
            siblingHullIndex = CellHulls(childHullID).time - CellTracks(parentTrackID).startTime + 1;
            % ASSERT ( siblingHullIndex > 0 && <= length(hulls)
            sibling = CellTracks(parentTrackID).hulls(siblingHullIndex);
            parentCosts(j) = parentCosts(j) + Tracker.SiblingDistance(childHullID,sibling);
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
    parentTrackID = Hulls.GetTrackID(parentHullID);
    
    if(isempty(parentTrackID))
        Error.ErrorHandling(['GetTrackID(' num2str(parentHullID) ') -- while in ProcessNewborns'],dbstack);
        return
    end
    
    % Don't try to add mitosis for track that ends before childtrack
    if ( CellTracks(parentTrackID).endTime < CellTracks(childTrackID).startTime )
        continue;
    end
    
    % Parent track must have a hull in the mitosis frame
    if ( isempty(Tracks.GetHullID(CellTracks(childTrackID).startTime, parentTrackID)) )
        continue;
    end
    
    % If the parent future is long enough create a mitosis
    connectTime = CellHulls(parentHullID).time+1;
    if( CONSTANTS.minParentHistoryTimeFrame < abs(CellTracks(childTrackID).startTime - CellTracks(parentTrackID).startTime)...
        || (GraphEdits(parentHullID,childHullID) > 0 && nnz(GraphEdits(parentHullID,:)) > 1) )
        Families.AddMitosis(childTrackID,parentTrackID,connectTime);
    end
end

if ( rootHull > 0 )
    trackID = Hulls.GetTrackID(rootHull);
    if ( ~isempty(trackID) )
        Figures.tree.familyID = CellTracks(trackID).familyID;
    end
end


consisencyErrs = mexIntegrityCheck();
if ( ~isempty(consisencyErrs) )
    msgbox('ERROR: Data corruption detected! Run integrity check for further details.', 'Data Consistency Error', 'error', 'modal');
end

end


