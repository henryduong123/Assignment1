
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
%     Copyright 2016 Drexel University
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

function WriteFrozenErrorCounts(rootDir)
    flist = dir(fullfile(rootDir,'*.mat'));

    fid = fopen(fullfile(rootDir,'errorCounts.csv'),'wt');
    fprintf(fid, 'Dataset, Clone ID, Hull Count, Track Count, Missing Hulls, User Seg Edits, User Track, Auto Seg Edits, User Seg Error %%, User Track Error %%, Total Seg Error %%\n');

    for i=1:length(flist)
        [datasetName, frozenTrees, hullCount, trackCount, missingCount, userSegEdits, userTrackEdits, autoSegEdits] = datasetErrors(rootDir,flist(i).name);
        if ( isempty(frozenTrees) )
            continue;
        end

        userSegPct = 100 * (userSegEdits ./ hullCount);
        userTrackPct = 100 * (userTrackEdits ./ (hullCount-1));
        totalSegPct = 100 * ((userSegEdits + autoSegEdits) ./ hullCount);

        for j=1:length(frozenTrees)
            fprintf(fid,'%s, %d, %d, %d, %d, %d, %d, %d, %f%%, %f%%, %f%%\n', datasetName, frozenTrees(j), hullCount(j), trackCount(j), missingCount(j), userSegEdits(j), userTrackEdits(j), autoSegEdits(j),userSegPct(j),userTrackPct(j), totalSegPct(j));
            
            datasetName = '';
        end
    end

    fclose(fid);
end

function [datasetName, frozenTrees, hullCount, trackCount, missingCount, userSegEdits, userTrackEdits, autoSegEdits] = datasetErrors(rootDir,dataName)
    hullCount = [];
    trackCount = [];
    missingCount = [];
    userSegEdits = [];
    autoSegEdits = [];
    userTrackEdits = [];

    datasetName = '';
    load(fullfile(rootDir,dataName));
    Load.FixOldFileVersions();

    frozenTrees = find([CellFamilies.bFrozen] ~= 0);
    if ( isempty(frozenTrees) )
        return;
    end

    datasetName = Metadata.GetDatasetName();

    for i=1:length(frozenTrees)
        [hullIDs missingHulls] = Families.GetAllHulls(frozenTrees(i));

        hullCount(i) = length(hullIDs);
        missingCount(i) = missingHulls;
        trackCount(i) = length(CellFamilies(frozenTrees(i)).tracks);

        userSegEdits(i) = Helper.GetFamilySegEditCount(frozenTrees(i),1,0);
        autoSegEdits(i) = Helper.GetFamilySegEditCount(frozenTrees(i),0,1);
        userTrackEdits(i) = Helper.GetFamilyTrackEditCount(frozenTrees(i),1,0);
    end
end
