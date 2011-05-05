%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
%     This file is part of LEVer.exe
%     (C) 2011 Andrew Cohen, Eric Wait and Mark Winter
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Adds the imagePixels field to older LEVer v3 hull structures, also fixes a
% bug in the old addNewSegmentHull code that could cause indexPixels to be
% non-integer valued
function AddImagePixelsField()
    global CONSTANTS CellHulls HashedCells
    
    oldCellHulls = CellHulls;
    CellHulls = struct(...
        'time',         {oldCellHulls.time},...
        'points',       {oldCellHulls.points},...
        'centerOfMass',	{oldCellHulls.centerOfMass},...
        'indexPixels',	{oldCellHulls.indexPixels},...
        'imagePixels',	cell(size(oldCellHulls)),...
        'deleted',      {oldCellHulls.deleted});

    progress = 1;
    iterations = length(HashedCells);
    for t=1:length(HashedCells)
        progress = progress+1;
        Progressbar(progress/iterations);
        imgfname = [CONSTANTS.rootImageFolder CONSTANTS.datasetName '_t' SignificantDigits(t) '.TIF'];
        [curimg map]=imread(imgfname);
        curimg=mat2gray(curimg);

        hullIdx = [HashedCells{t}.hullID];
        for i=1:length(hullIdx)
            % Fix data from old add-hull bug
            if ( any(round(CellHulls(hullIdx(i)).indexPixels) ~= CellHulls(hullIdx(i)).indexPixels) )
                if ( size(CellHulls(hullIdx(i)),1) == 1 )
                    CellHulls(hullIdx(i)).indexPixels = sub2ind(CONSTANTS.imageSize, round(CellHulls(hullIdx(i)).points(:,2)), round(CellHulls(hullIdx(i)).points(:,1)));
                end
            end

            % Get imagePixels from intensity data
            CellHulls(hullIdx(i)).imagePixels = curimg(CellHulls(hullIdx(i)).indexPixels);
        end
    end
    Progressbar(1);%clear it out
end