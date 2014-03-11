function Backtracker()
    global bDirty Figures EditFamIdx CellFamilies HashedCells SelectStruct stains stainColors BackTrackIdx BackSelectHulls
    
    stains = [];
    stainColors = [];
    BackSelectHulls = [];
    BackTrackIdx = [];
    bLoaded = openData();
    if ( ~bLoaded )
        return;
    end
    
    bDirty = false;
    
    % Figure quantities
    Figures.cells.handle = figure();
    Figures.tree.handle = figure();
    
    Figures.tree.timeIndicatorLine = [];
    Figures.tree.trackMap = [];
    
    Figures.tree.trackingLine = [];
    Figures.tree.trackingLabel = [];
    Figures.tree.trackingBacks = [];
    
    Figures.time = length(HashedCells);
    
    Figures.tree.familyID = [];
    
    SelectStruct.editingHullID = [];
    SelectStruct.selectedTrackID = [];
    SelectStruct.selectSignedCost = [];
    
    SelectStruct.selectCosts = [];
    SelectStruct.selectPaths = [];
    
    % Drag: like mitosis interface.
    % Clicking selects a cell (or stain) to track backwards/forwards, only display reseg-edited families. Show partial tree?
    % left-click add hull/right-click delete hull or mitosis (from track)
    
    bLockedFam = ([CellFamilies.bLocked] > 0);
    EditFamIdx = find(bLockedFam);
    
    Backtracker.UpdateBacktrackHulls();
    
    Backtracker.DrawCells();
    Backtracker.DrawTree();
    Backtracker.SetFigureHandlers();
end

%%%%%%%%%%%%%%%%%%%%%%

function bLoaded = openData()
    global CONSTANTS stains stainColors
    
    bLoaded = false;
    
    fprintf('Select .mat data file...\n');
    [dataFile,dataPath,filterIdx] = uigetfile('*.mat', 'Open Data');

    if ( filterIdx == 0 )
        return
    end
    
    fprintf('Opening file...');
    load(fullfile(dataPath,dataFile));

    Load.AddConstant('matFullFile', fullfile(dataPath,dataFile), 1);
    
    if ( ~isfield(CONSTANTS,'imageNamePattern') || exist(Helper.GetFullImagePath(1),'file')~=2 )
        imagesPath = openImages(dataPath);
        if ( isempty(imagesPath) )
            return
        end
    end

    Load.InitializeConstants();
    bUpdated = Load.FixOldFileVersions();
    
    % Check this at the end of load now for new and old data alike
    errors = mexIntegrityCheck();
    if ( ~isempty(errors) )
        warndlg('There were database inconsistencies.  LEVer might not behave properly!');
        Dev.PrintIntegrityErrors(errors);
    end
    
    % Initialized cached costs here if necessary (placed after fix old file versions for compatibility)
    Load.InitializeCachedCosts(0);
    
    if ( isempty(stainColors) )
        bLoaded = openStainInfo(dataPath);
    else
        bLoaded = true;
    end
end

function bLoaded = openStainInfo(dataPath)
    global CONSTANTS
    
    bLoaded = false;
    
    while ( 1 )
        datasetString = '';
        if ( isfield(CONSTANTS,'datasetName') )
            datasetString = CONSTANTS.datasetName;
        end
        
        [fileName,pathName,filterIndex] = uigetfile(fullfile(dataPath, '*.mat'), ['Load Stain Info (' datasetString '): ']);
        if ( filterIndex == 0 )
            return;
        end

        loadFilePath = fullfile(pathName, fileName);
        s = load(loadFilePath);
        
        if ( ~all(isfield(s, {'datasetName' 'stains' 'stainColors'})) )
            resp = questdlg('Error: File selected does not contain stain data', 'Invalid File', 'Ok','Cancel','Ok');
            if ( strcmpi(resp, 'Cancel') )
                return;
            end
            
            continue;
        end
        
        if ( ~strcmpi(s.datasetName,CONSTANTS.datasetName) )
            resp = questdlg('Warning: File selected does not match the current data set, load anyway?', 'Dataset Mismatch', 'Yes','No','Cancel','No');
            if ( strcmpi(resp, 'Cancel') )
                return;
            elseif ( strcmpi(resp, 'No') )
                continue;
            end
        end
        
        break;
    end
    
    loadStainInfo(loadFilePath);
    
    bLoaded = true;
end

function loadStainInfo(loadStainPath)
    global stains stainColors
    
    s = load(loadStainPath);
    
    stains = s.stains;
    stainColors = s.stainColors;
end

function imagesPath = openImages(matPath)
    global CONSTANTS
    
    imagesPath = [];
    while ( isempty(imagesPath) )
        datasetString = '';
        if ( isfield(CONSTANTS,'datasetName') )
            datasetString = CONSTANTS.datasetName;
        end

        [imageFile, imagesPath, filterIdx] = uigetfile(fullfile(matPath, '*.tif'),['Open First Image in Dataset (' datasetString '): ' ]);
        if ( filterIdx == 0 )
            return
        end
        
        [sigDigits imageDataset] = Helper.ParseImageName(imageFile, 0);
        if ( isempty(datasetString) )
            CONSTANTS.datasetName = imageDataset;
        end
        
        if ( strcmp(imageDataset,[CONSTANTS.datasetName '_']) )
            Load.AddConstant('datasetName', [CONSTANTS.datasetName '_'], 1);
        elseif ( ~strcmp(imageDataset,CONSTANTS.datasetName) )
            answer = questdlg('Image does not match dataset would you like to choose another?','Image Selection','Yes','No','Close','Yes');
            switch answer
                case 'Yes'
                    imagesPath = [];
                    continue;
                case 'No'
                    Load.AddConstant('imageNamePattern', '', 1);
                case 'Close'
                    imagesPath = [];
                    return
            end
        end
    end
    
    Load.AddConstant('rootImageFolder', imagesPath, 1);
    Load.AddConstant('imageSignificantDigits', sigDigits, 1);
end
