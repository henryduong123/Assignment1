% CellCountDifference
% Computes the difference between the number of cells in the tree and
% the number of cells in the cell window

% Created 2/7/2014 ABK

% place function in DrawCells
% relevant files: InitializeFigures, DrawCells

% Count should be updated each frame
% Change color & size if cells are missing ie red = missing cells - goes in
% DrawCells

function cellDiff = CellCountDifference()
    global Figures CellFamilies

    cellDiff = 0;
    
    FamID = Figures.tree.familyID;
    
    familyTracks = CellFamilies(FamID).tracks;
    if ( isempty(familyTracks) )
        return;
    end

    hulls = zeros(1,length(familyTracks));
    % Tracks.GetHullID() to check if hull exists in that time.  0 if no hull
    % exists - nnz()
    for k = 1:length(familyTracks)
        hulls(k) = Tracks.GetHullID(Figures.time, familyTracks(k));
    end
    
    hullCount = nnz(hulls);
    cellDiff = Figures.cellCount - hullCount;
end
