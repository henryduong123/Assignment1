function bNeedsUpdate = FixDefaultPhenotypes()
    % Merge together any duplicate phenotypes (based on description)
    bNeedsUpdate = mergeDuplicateIDs();
    
    % Create the default 'ambiguous' phenotype and merge with any
    % equivalent descriptors. Force phenoID = 2.
    equivAmbigDesc = {'ambiguous', 'unknown'};
    
    phenoIDs = findEquivalentPhenotype(equivAmbigDesc);
    mergePhenoID = mergePhenotypes(phenoIDs);
    
    [phenoID bChangeDesc] = setPhenotype(mergePhenoID, 'ambiguous', [.549 .28235 .6235]);
    bForcedChange = forcePhenotypeID(phenoID, 2);
    
    bNeedsUpdate = (bNeedsUpdate || bChangeDesc || bForcedChange);
    
    % Create the default 'off screen' phenotype and merge with any
    % equivalent descriptors. Force phenoID = 3.
    equivOffscreenDesc = {'left field of vision',...
                          'left','top','bottom','right',...
                          'off screen','offscreen',...
                          'leftscreen','left screen',...
                          'left_screen','left-screen',...
                          'left frame','left_frame',...
                          'left-frame'};
	
    phenoIDs = findEquivalentPhenotype(equivOffscreenDesc);
    mergePhenoID = mergePhenotypes(phenoIDs);
    
    [phenoID bChangeDesc] = setPhenotype(mergePhenoID, 'off screen', [.31 .87 .89]);
    bForcedChange = forcePhenotypeID(phenoID, 3);
    
    bNeedsUpdate = (bNeedsUpdate || bChangeDesc || bForcedChange);
end

% Find all phenotypes IDs matching one of the equivalent descriptions list
function phenoIDs = findEquivalentPhenotype(equivDescriptions)
    global CellPhenotypes
    
    phenoIDs = [];
    for i=1:length(equivDescriptions)
        equivID = find(strcmpi(equivDescriptions{i},CellPhenotypes.descriptions));
        phenoIDs = [phenoIDs equivID];
    end
end

% Merge all specified phenoIDs into the smallest phenoID
function mergePhenoID = mergePhenotypes(phenoIDs)
    global CellPhenotypes
    
    mergePhenoID = [];
    if ( isempty(phenoIDs) )
        return;
    end
    
    % find the smallest phenoiD
    mergePhenoID = min(phenoIDs);
    
    keepIdx = setdiff(1:length(CellPhenotypes.descriptions), phenoIDs);
    keepIdx = sort([keepIdx mergePhenoID]);
    
    remapIDs = mergePhenoID * ones(1,length(CellPhenotypes.descriptions));
    remapIDs(keepIdx) = 1:length(keepIdx);
    
    CellPhenotypes.descriptions = CellPhenotypes.descriptions(keepIdx);
    CellPhenotypes.colors = CellPhenotypes.colors(keepIdx,:);
    CellPhenotypes.hullPhenoSet(2,:) = remapIDs(CellPhenotypes.hullPhenoSet(2,:));
end

% Force phenoID to be newID swap the old phenotype if necessary, without
% losing the integrity of marked cells
function bNeedsUpdate = forcePhenotypeID(phenoID, newID)
    global CellPhenotypes
    
    bNeedsUpdate = false;
    if ( phenoID == newID )
        return
    end
    
    bNeedsUpdate = true;
    
    phenoDesc = CellPhenotypes.descriptions{phenoID};
    phenoColor = CellPhenotypes.colors(phenoID,:);
    
    CellPhenotypes.descriptions{phenoID} = CellPhenotypes.descriptions{newID};
    CellPhenotypes.colors(phenoID,:) = CellPhenotypes.colors(phenoID,:);
    
    CellPhenotypes.descriptions{newID} = phenoDesc;
    CellPhenotypes.colors(newID,:) = phenoColor;
    
    
    oldHullsIdx = find(CellPhenotypes.hullPhenoSet(2,:) == phenoID);
    newHullsIdx = find(CellPhenotypes.hullPhenoSet(2,:) == newID);
    CellPhenotypes.hullPhenoSet(2,oldHullsIdx) = newID;
    CellPhenotypes.hullPhenoSet(2,newHullsIdx) = phenoID;
end

% Set description and colors for phenotype, create new phenotype if phenoID
% is empty
function [newPhenotypeID bNeedsUpdate] = setPhenotype(phenoID, description, color)
    global CellPhenotypes
    
    bNeedsUpdate = true;
    newPhenotypeID = phenoID;
    if ( isempty(phenoID) )
        newPhenotypeID = length(CellPhenotypes.descriptions)+1;
    elseif ( strcmp(CellPhenotypes.descriptions{newPhenotypeID}, description) )
        bNeedsUpdate = false;
    end
    
    CellPhenotypes.descriptions{newPhenotypeID} = description;
    CellPhenotypes.colors(newPhenotypeID,:) = color;
end

% Merge any duplicate IDs
function bNeedsUpdate = mergeDuplicateIDs()
    global CellPhenotypes
    
    bNeedsUpdate = false;
    
    uniqueCell = {};
    for i=1:length(CellPhenotypes.descriptions)
        if ( ~any(strcmpi(CellPhenotypes.descriptions{i},uniqueCell)) )
            uniqueCell = [uniqueCell; CellPhenotypes.descriptions(i)];
        end
    end
    
    for j = 1:length(uniqueCell)
        equivID = find(strcmpi(uniqueCell{j},CellPhenotypes.descriptions));
        mergePhenoID = mergePhenotypes(equivID);
    end
    
    if ( length(uniqueCell) < length(CellPhenotypes.descriptions) )
        bNeedsUpdate = true;
    end
end

