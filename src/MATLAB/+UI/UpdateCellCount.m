% UpdateCellCount
% Counts number of cells in active tree
% Created 1/31/2014 ABK

% To do - compare to number of active cells in image to find "missing"
% cells

% place in UpdateTimeIndicatorFunction
% relevant files: DrawTree, InitializeFigures, 

% Count should be updated each frame

function cellCount = UpdateCellCount()
global CellTracks Figures CellFamilies 
% get family ID			Figures.tree.familyID
FamID = Figures.tree.familyID;
familyTracks = CellFamilies(FamID).tracks;
cellCount = 0;

% %vectorized
% startTimes = [CellTracks(familyTracks).startTime];
% endTimes = [CellTracks(familyTracks).endTime];
% cellCount = nnz((Figures.time >= startTimes) & (Figures.time <= endTimes));

% non-vectorized
    for k = 1:length(familyTracks)
        % count those that start before & end after current time 	Figures.time
        if ((CellTracks(familyTracks(k)).startTime <= Figures.time) && ...
                    (CellTracks(familyTracks(k)).endTime >= Figures.time))
                cellCount = cellCount +1;

            % CellFamilies - family ID index	Figures.tree.familyID
            % start & end time for each track
        end
    end 

end