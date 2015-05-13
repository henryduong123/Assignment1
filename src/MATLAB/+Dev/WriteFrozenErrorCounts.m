function WriteFrozenErrorCounts(rootDir)
    flist = dir(fullfile(rootDir,'*.mat'));

    fid = fopen(fullfile(rootDir,'errorCounts.csv'),'wt');
    fprintf(fid, 'Dataset, Clone ID, Hull Count, Missing Hulls, User Edits, Auto Edits, User Error %%, Total Error %%\n');

    for i=1:length(flist)
        [datasetName, frozenTrees, hullCount, missingCount, userEdits, autoEdits] = datasetErrors(rootDir,flist(i).name);
        if ( isempty(frozenTrees) )
            continue;
        end

        userPct = 100 * (userEdits ./ (2*hullCount - 1));
        totalPct = 100 * ((userEdits + autoEdits) ./ (2*hullCount - 1));

        fprintf(fid,'%s, %d, %d, %d, %d, %d, %f%%, %f%%\n', datasetName, frozenTrees(1), hullCount(1), missingCount(1), userEdits(1), autoEdits(1),userPct(1),totalPct(1));
        for j=2:length(frozenTrees)
            fprintf(fid,'%s, %d, %d, %d, %d, %d, %f%%, %f%%\n', '', frozenTrees(j), hullCount(j), missingCount(j), userEdits(j), autoEdits(j),userPct(j),totalPct(j));
        end
    end

    fclose(fid);
end

function [datasetName, frozenTrees, hullCount, missingCount, userEdits, autoEdits] = datasetErrors(rootDir,dataName)
    hullCount = [];
    missingCount = [];
    userEdits = [];
    autoEdits = [];

    datasetName = '';
    load(fullfile(rootDir,dataName));

    frozenTrees = find([CellFamilies.bFrozen] ~= 0);
    if ( isempty(frozenTrees) )
        return;
    end

    datasetName = CONSTANTS.datasetName;

    for i=1:length(frozenTrees)
        [hullIDs missingHulls] = Families.GetAllHulls(frozenTrees(i));

        hullCount(i) = length(hullIDs);
        missingCount(i) = missingHulls;

        userEdits(i) = Helper.GetFamilyEditCount(frozenTrees(i),1,0);
        autoEdits(i) = Helper.GetFamilyEditCount(frozenTrees(i),0,1);
    end
end
