
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
%     Copyright 2011-2016 Andrew Cohen
%
%     This file is part of LEVer - the tool for stem cell lineaging. See
%     http://n2t.net/ark:/87918/d9rp4t for details
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

function bNeedsUpdate = AddFamilyEditFields()
    global CellFamilies
    
    bNeedsUpdate = false;
    
    % Add bLockedField if necessary
    if ( ~isfield(CellFamilies, 'bLocked') )
        CellFamilies = addDefaultField(CellFamilies, 'bLocked', false);
        bNeedsUpdate = true;
    end
    
    if ( ~isfield(CellFamilies, 'bCompleted') )
        CellFamilies = addDefaultField(CellFamilies, 'bCompleted', false);
        bNeedsUpdate = true;
    end
    
    if ( ~isfield(CellFamilies, 'correctedTime') )
        CellFamilies = addDefaultField(CellFamilies, 'correctedTime', false);
        
        lockedFamIDs = find([CellFamilies.bLocked] ~= 0);
        for i=1:length(lockedFamIDs)
            CellFamilies(lockedFamIDs(i)).correctedTime = getCorrectedTime(lockedFamIDs(i));
        end
        
        bNeedsUpdate = true;
    end
    
    if ( ~isfield(CellFamilies, 'editInfo') )
        CellFamilies = addDefaultField(CellFamilies, 'editInfo', struct('editedBy',{''}, 'startDate',{[]}, 'endDate',{[]}, 'manualTime',{0}, 'autoTime',{0}));
        bNeedsUpdate = true;
    end
    
    if ( ~isfield(CellFamilies, 'bFrozen') )
        CellFamilies = addDefaultField(CellFamilies, 'bFrozen', false);
        bNeedsUpdate = true;
    end
    
    if ( ~isfield(CellFamilies, 'extFamily') )
        CellFamilies = addDefaultField(CellFamilies, 'extFamily', []);
        bNeedsUpdate = true;
    end
end

function outStruct = addDefaultField(inStruct, fieldName, defaultVal)
    outStruct = inStruct;
    [outStruct.(fieldName)] = deal(defaultVal);
end

function correctedTime = getCorrectedTime(familyID)
    global CellFamilies CellTracks CellHulls ResegLinks
    
    correctedTime = 0;
    familyTracks = CellFamilies(familyID).tracks;
    if ( isempty(familyTracks) )
        return;
    end
    
    familyLength = CellFamilies(familyID).endTime - CellFamilies(familyID).startTime + 1;
    if ( familyLength < 100 )
        return;
    end
    
    guessTime = guessCorrectedTime(familyID);
    if ( any(ResegLinks(:) == familyID) )
        familyHullIDs = [CellTracks(familyTracks).hulls];
        
        [fromHullIDs toHullIDs] = find(ResegLinks == familyID);
        correctedTime = max([CellHulls(toHullIDs).time]);
        
        if ( (length(fromHullIDs) / length(familyHullIDs)) < 0.75 )
            correctedTime = guessTime;
        end
        
        return;
    end
    
    correctedTime = guessTime;
end

% Use a technique similar to Otsu to guess the last resegmented frame.
function correctedTime = guessCorrectedTime(familyID)
    global CellHulls CellTracks CellFamilies
    
    famTracks = CellFamilies(familyID).tracks;
    
    trackStarts = [CellTracks(famTracks).startTime];
    trackEnds = [CellTracks(famTracks).endTime];
    
    trackHulls = [CellTracks(famTracks).hulls];
    validTrackHulls = trackHulls(trackHulls > 0);
    hullTimes = [CellHulls(validTrackHulls).time];
    
    startChkTime = CellFamilies(familyID).startTime+1;
    endChkTime = CellFamilies(familyID).endTime-1;
    chkLength = endChkTime - startChkTime + 1;
    
    hullCount = arrayfun(@(t)(nnz(hullTimes==t)), startChkTime:endChkTime);
    trackCount = zeros(1,chkLength);
    for i=1:length(trackStarts)
        startIdx = max(1, trackStarts(i) - startChkTime + 1);
        endIdx = min(chkLength,trackEnds(i) - startChkTime + 1);
        
        trackCount(startIdx:endIdx) = trackCount(startIdx:endIdx) + 1;
    end
    
    inTrackBefore = cumsum(trackCount);
    hullBefore = cumsum(hullCount);
    
    totalHulls = length(validTrackHulls);
    totalTrackSize = length(trackHulls);
    
    bValidBefore = (inTrackBefore > 0);
    bValidAfter = (totalTrackSize-inTrackBefore > 0);
    
    beforeMeans = zeros(1,chkLength);
    afterMeans = zeros(1,chkLength);
    
    beforeMeans(bValidBefore) = hullBefore(bValidBefore) ./ inTrackBefore(bValidBefore);
    afterMeans(bValidAfter) = (totalHulls - hullBefore(bValidAfter)) ./ (totalTrackSize-inTrackBefore(bValidAfter));
    
    sstdBA = (beforeMeans - afterMeans);
    
    [sstdMax correctedTime] = max(sstdBA);
    editMean = beforeMeans(correctedTime);
    
    if ( editMean < 0.5 )
        correctedTime = CellFamilies(familyID).startTime;
        return;
    end
    
    if ( sstdMax < 0.5 )
        correctedTime = CellFamilies(familyID).endTime;
        return;
    end
end
