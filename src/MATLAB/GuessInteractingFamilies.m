%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
%     This file is part of LEVer.exe
%     (C) 2011 Andrew Cohen, Eric Wait and Mark Winter
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Guess at families that interact with the given family ID within a
% specified radius
function [families bAssumedEdited] = GuessInteractingFamilies(trackID, hullCheckRadiusSq)
    global CellFamilies CellHulls HashedCells CellTracks
    
    familyID = CellTracks(trackID).familyID;
    
    families = [];
    for t=1:length(HashedCells)-1
        familyHulls = [HashedCells{t}([CellTracks([HashedCells{t}.trackID]).familyID] == familyID).hullID];
        
        bNonfamily = [CellTracks([HashedCells{t+1}.trackID]).familyID] ~= familyID;
        nonfamilyHulls = [HashedCells{t+1}(bNonfamily).hullID];
        
        if ( isempty(familyHulls) || isempty(nonfamilyHulls) )
            continue;
        end
        
        famCOM = cat(1,CellHulls(familyHulls).centerOfMass);
        nonfamCOM = cat(1,CellHulls(nonfamilyHulls).centerOfMass);
        
        distSq = (ones(size(nonfamCOM,1),1)*(famCOM(:,1)') - nonfamCOM(:,1)*ones(1,size(famCOM,1))).^2 + (ones(size(nonfamCOM,1),1)*(famCOM(:,2)') - nonfamCOM(:,2)*ones(1,size(famCOM,1))).^2;
        bInteractions = (min(distSq,[],2)' <= hullCheckRadiusSq);
        
        nonfamilyHash = HashedCells{t+1}(bNonfamily);
        intFamilies = [CellTracks([nonfamilyHash(bInteractions).trackID]).familyID];
        
        families = union(families, intFamilies);
    end
    
    families = [familyID families];
    bAssumedEdited = ([CellFamilies(families).startTime] == 1 & [CellFamilies(families).endTime] == length(HashedCells));
end