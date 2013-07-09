% segEdits = ResegFromTree(rootTracks)
% 
% Attempt to correct segmentation (and tracking) errors by exploiting a
% corrected lineage tree.
% 
% rootTracks - List of root tree tracks to resegment

function tLast = ResegFromTree(rootTracks, tStart, tEnd)
    global HashedCells CellTracks CellHulls Costs
    
    global Figures CONSTANTS
    outMovieDir = fullfile('B:\Users\mwinter\Documents\Figures\Reseg',CONSTANTS.datasetName);
    
    if ( ~exist('tStart','var') )
        tStart = 2;
    end
    
    if ( ~exist('tEnd','var') )
        tEnd = length(HashedCells);
    end
    
    tStart = max(tStart,2);
    tMax = length(HashedCells);
    tEnd = min(tEnd, tMax);
    
    checkTracks = Segmentation.ResegFromTree.GetSubtreeTracks(rootTracks);
    
    invalidPreserveTracks = [];
    
    % Need to worry about deleted hulls?
    costMatrix = Costs;
    bDeleted = ([CellHulls.deleted] > 0);
    costMatrix(bDeleted,:) = 0;
    costMatrix(:,bDeleted) = 0;
    
    mexDijkstra('initGraph', costMatrix);
    
    for t=tStart:tEnd
        checkTracks = setdiff(checkTracks, invalidPreserveTracks);
        
        newPreserveTracks = Segmentation.ResegFromTree.FixupSingleFrame(t, checkTracks, tMax);
        
        checkTracks = [checkTracks newPreserveTracks];
        [dump sortedIdx] = unique(checkTracks, 'first');
        sortedIdx = sort(sortedIdx);
        checkTracks = checkTracks(sortedIdx);
        
        bInvalidPreserveTracks = cellfun(@(x)(isempty(x)),{CellTracks(checkTracks).startTime});
        invalidPreserveTracks = checkTracks(bInvalidPreserveTracks);
        
        % DEBUG
        Figures.time = t;
        validPreserveTracks = checkTracks(~bInvalidPreserveTracks);
        famID = CellTracks(validPreserveTracks(1)).familyID;
        
        UI.DrawTree(famID);
        UI.TimeChange(t);
        drawnow();
        
        % Make Movie code
%         saveMovieFrame(t, famID, outMovieDir);
        
        tLast = t;
    end
    
%     saveMovieFrame(1, famID, outMovieDir);
end

function saveMovieFrame(t, famID, outdir)
    global Figures CONSTANTS
    
    UI.DrawTree(famID);
    UI.TimeChange(t);
    drawnow();
    
    if ( ~exist(outdir, 'dir') )
        recmkdir(outdir);
    end
    
    figure(Figures.cells.handle)
    XCells = getframe();
    imwrite(XCells.cdata, fullfile(outdir,['cells_' CONSTANTS.datasetName num2str(t, '%04d') '.tif']), 'tiff');

    figure(Figures.tree.handle)
    XTree = getframe();
    imwrite(XTree.cdata, fullfile(outdir,['tree_' CONSTANTS.datasetName num2str(t, '%04d') '.tif']), 'tiff');
    
    frameSize = [size(XCells.cdata); size(XTree.cdata)];
    outSize = max(frameSize,[],1);
    imOut = [imresize(XCells.cdata, outSize(1:2)) imresize(XTree.cdata, outSize(1:2))];
    imwrite(imOut, fullfile(outdir,['_comb_' CONSTANTS.datasetName num2str(t, '%04d') '.tif']), 'tiff');
end

