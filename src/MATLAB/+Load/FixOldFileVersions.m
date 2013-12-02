% FixOldFileVersions.m - Used during OpenData.m to update older LEVer data
% files.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
%     Copyright 2011 Andrew Cohen, Eric Wait and Mark Winter
%
%     This file is part of LEVer - the tool for stem cell lineaging. See
%     https://pantherfile.uwm.edu/cohena/www/LEVer.html for details
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

function bNeedsUpdate = FixOldFileVersions()
    global CellHulls CellFamilies HashedCells ConnectedDist GraphEdits ResegLinks Costs CellPhenotypes CellTracks ReplayEditActions Log

    bNeedsUpdate = 0;
    
    emptyHash = find(cellfun(@(x)(isempty(x)), HashedCells));
    if ( ~isempty(emptyHash) )
        for i=1:length(emptyHash)
            HashedCells{emptyHash(i)} = struct('hullID',{}, 'trackID',{});
        end
    end
    
    % Add color field to phenotype structure as of ver 7.2
    
    if ( ~isfield(CellPhenotypes,'colors') )
        CellPhenotypes.colors = hsv(length(CellPhenotypes.descriptions));
        CellPhenotypes.colors(1,:) = [0 0 0];
    end
    % Will search older versions of the code for any variation of ambiguous
    % or off screen and replace them with 'ambiguous' or 'off screen' will
    % merge other ambiguous ones and create new code.
    if (isfield(CellPhenotypes,'descriptions'))
        MergeDuplicateIDs(CellPhenotypes.descriptions);
        phenoIDs = findEquivalentPhenotype({'ambiguous', 'unknown'});
        mergePhenoID = mergePhenotypes(phenoIDs);
        if ( isempty(mergePhenoID) )
            mergePhenoID = NewPhenotypes('ambiguous',[.549 .28235 .6235]);
        else
            CellPhenotypes.descriptions{mergePhenoID} = 'ambiguous';
            CellPhenotypes.colors(mergePhenoID,:) = [.549 .28235 .6235];
        end
        SwapPhenotypeID(CellPhenotypes.descriptions(2),2,mergePhenoID);
        
        
        phenoIDs = findEquivalentPhenotype({'left field of vision','left','top','bottom','right','off screen','offscreen','leftscreen','left screen','left_screen','left-screen','left frame','left_frame','left-frame'});
        mergePhenoID = mergePhenotypes(phenoIDs);
        if ( isempty(mergePhenoID) )
            mergePhenoID = NewPhenotypes('off screen',[.31 .87 .89]);
        else
            CellPhenotypes.descriptions{mergePhenoID} = 'off screen';
            CellPhenotypes.colors(mergePhenoID,:) = [.31 .87 .89];
        end
        SwapPhenotypeID(CellPhenotypes.descriptions(3),3,mergePhenoID);  
    end
   
    % Add imagePixels field to CellHulls structure (and resave in place)
    if(~isfield(CellHulls, 'imagePixels'))
        fprintf('\nAdding Image Pixel Information...\n');
        Load.AddImagePixelsField();
        fprintf('Image Information Added\n');
        bNeedsUpdate = 1;
    end
    
    % Need userEdited field as of ver 5.0
    if ( ~isfield(CellHulls, 'userEdited') )
        Load.AddUserEditedField();
        bNeedsUpdate = 1;
    end
    
    % Remove HashedCells.editedFlag field as of ver 7.0
    if ( ~isempty(HashedCells) )
        for t=1:length(HashedCells)
            if ( isfield(HashedCells{t}, 'editedFlag') )
                HashedCells{t} = rmfield(HashedCells{t}, 'editedFlag');
                bNeedsUpdate = 1;
            end
        end
    end
    
    if ( isempty(GraphEdits) )
        GraphEdits = sparse([], [], [], size(Costs,1), size(Costs,2), round(0.1*size(Costs,2)));
        bNeedsUpdate = 1;
    end
    
    if ( isempty(ResegLinks) )
        ResegLinks = sparse([], [], [], size(Costs,1), size(Costs,2), round(0.1*size(Costs,2)));
        bNeedsUpdate = 1;
    end

    % Calculate connected-component distance for all cell hulls (out 2 frames)
    if ( ~Load.CheckFileVersionString('4.3') || isempty(ConnectedDist) )
        fprintf('\nBuilding Cell Distance Information...\n');
        ConnectedDist = [];
        mexCCDistance(1:length(CellHulls),0);
%         Tracker.BuildConnectedDistance(1:length(CellHulls), 0, 1);
        fprintf('Finished\n');
        bNeedsUpdate = 1;
    end
    
    % Remove CellTracks.phenotype field and use it to create hullPhenoSet
    % instead
    if ( ~Load.CheckFileVersionString('5.0') || (~isfield(CellPhenotypes,'hullPhenoSet') && isfield(CellTracks,'phenotype') && isfield(CellTracks,'timeOfDeath')) )
        fprintf('\nConverting Phenotype information...\n');
        Load.UpdatePhenotypeInfo();
        fprintf('Finished\n');
        bNeedsUpdate = 1;
    end
    
%     % Adds the special origin action, to indicate that this is initial
%     % segmentation data from which edit actions are built.
%     if ( isempty(ReplayEditActions) || bNeedsUpdate )
%         Editor.ReplayableEditAction(@Editor.OriginAction, 1);
%         bNeedsUpdate = 1;
%     end
    
    % Add in random state to replayable action context
    if ( ~isempty(ReplayEditActions) && ~isfield(ReplayEditActions,'randState') )
        randFcns = {'Editor.LearnFromEdits','Editor.SplitCell'};
        oldReplayEditActions = ReplayEditActions;
        
        ReplayEditActions = struct('funcName',{}, 'funcPtr',{}, 'args',{}, 'ret',{}, ...
                    'histAct',{}, 'bErr',{}, 'randState',{}, 'ctx',{}, 'chkHash',{});
        
        for i=1:length(oldReplayEditActions)
            funcName = oldReplayEditActions(i).funcName;
            randState = [];
            args = oldReplayEditActions(i).args;
            if ( any(strcmp(funcName,randFcns)) )
                randState = oldReplayEditActions(i).args{end};
                args = oldReplayEditActions(i).args(1:end-1);
            end
            
            ReplayEditActions = [ReplayEditActions; Helper.MakeInitStruct(ReplayEditActions, oldReplayEditActions(i))];
            ReplayEditActions(end).args = args;
            ReplayEditActions(end).randState = randState;
        end
        
        bNeedsUpdate = 1;
    end
    
    % Add bLockedField if necessary
    if ( ~isfield(CellFamilies, 'bLocked') )
        Load.AddLockedField();
        bNeedsUpdate = 1;
    end
    
    % Make sure that CellHulls userEdited, deleted, greenInd
    % are all "logical". Also, CellFamilies.bLocked
    CellHulls = forceLogicalFields(CellHulls, 'userEdited','deleted','greenInd');
    CellFamilies = forceLogicalFields(CellFamilies, 'bLocked');
    
    bEmptyHulls = arrayfun(@(x)(isempty(x.deleted)), CellHulls);
    emptyIdx = find(bEmptyHulls);
    for i=1:length(emptyIdx)
        CellHulls(emptyIdx(i)).deleted = true;
        CellHulls(emptyIdx(i)).userEdited = false;
    end
    
    % Get rid of timer handle in Log
    for i=1:length(Log)
        if(isfield(Log(i),'figures'))
            if(isfield(Log(i).figures,'advanceTimerHandle'))
                Log(i).figures.advanceTimerHandle = [];
            end
        end
    end
end

function outStruct = forceLogicalFields(inStruct, varargin)
    validFields = cell(0,0);
    
    for i=1:length(varargin)
        if ( isfield(inStruct,varargin{i}) )
            validFields = [validFields; {varargin{i}}];
        end
    end
    
    outStruct = inStruct;
    for i=1:length(inStruct)
        for j=1:length(validFields)
            if ( isempty(outStruct(i).(validFields{j})) )
                outStruct(i).(validFields{j}) = false;
            else
                outStruct(i).(validFields{j}) = (outStruct(i).(validFields{j}) ~= 0);
            end
        end
    end
end
<<<<<<< PhenotypeMerge
=======
<<<<<<< MultiCellTypes
=======
>>>>>>> local

function phenoIDs= findEquivalentPhenotype(equivDescriptions)
%This will look for an equivalent description
    global CellPhenotypes
    phenoIDs = [];
    for i=1:length(equivDescriptions)
        equivID = find(strcmpi(equivDescriptions{i},CellPhenotypes.descriptions));
        phenoIDs = [phenoIDs equivID];
    end
end

function mergePhenoID = mergePhenotypes(phenoIDs)
% This will find the smallest phenoId that is equivalent and merge them
% together if they find an equivalent.
global CellPhenotypes
    mergePhenoID = [];
    
    if (isempty(phenoIDs))
        return;
    end
    
    % find the smallest phenoiD
    mergePhenoID = min(phenoIDs);
    
    keepIdx = setdiff(1:length(CellPhenotypes.descriptions),phenoIDs);
    keepIdx = sort([keepIdx mergePhenoID]);
    
    remapIDs = mergePhenoID * ones(1,length(CellPhenotypes.descriptions));
    remapIDs(keepIdx) = 1:length(keepIdx);
    
    CellPhenotypes.descriptions = CellPhenotypes.descriptions(keepIdx);
    CellPhenotypes.colors = CellPhenotypes.colors(keepIdx,:);
    CellPhenotypes.hullPhenoSet(2,:) = remapIDs(CellPhenotypes.hullPhenoSet(2,:));
end
function SwapPhenotypeID(CellIndx,cellPlacementId,MergeId)
% This will swap the phenotypes to the respective spots where it is suppose
% to be in the program, without losing the integrity of the cells 
global CellPhenotypes
        if(cellPlacementId == MergeId)
            return
        end
        cellIdx = find(CellPhenotypes.hullPhenoSet(2,:) == find(strcmpi(MergeID,CellPhenotypes.descriptions)));
        nCellidx = find(CellPhenotypes.hullPhenoSet(2,:) == cellPlacementId);
                CellPhenotypes.descriptions(CellIndx) = CellPhenotypes.descriptions{MergeId};
                CellPhenotypes.colors(CellIndx,:) =  CellPhenotypes.colors(cellPlacementId,:);
                CellPhenotypes.descriptions(cellPlacementId) = {MergeID};
                CellPhenotypes.colors(cellPlacementId,:) = CellPhenotype.colors(MergeID);
                CellPhenotypes.hullPhenoSet(2,cellIdx)=cellPlacementId;
                CellPhenotypes.hullPhenoSet(2,nCellidx)= CellIndx;
            
end
function [NewPhenotypeID]= NewPhenotypes(description,color)
%will create a new phenotype and add the colors and output the description
%as a new phenotypeID
global CellPhenotypes
    CellPhenotypes.descriptions{end+1} = description;
    CellPhenotypes.colors(end+1,:) = color;
    NewPhenotypeID =length(CellPhenotypes.descriptions);
end
function [mergePhenoID]=MergeDuplicateIDs(description)
global CellPhenotypes
<<<<<<< PhenotypeMerge

    uniqueCell = unique(description(:));
    mergeIDsRepeated = numel(uniqueCell) ~= numel(description)
    mergePhenoID = mergePhenotypes(mergeIDsRepeated);
end
=======
 phenoIDs = [];
  for i=1:length(description)
%     uniqueCell(i) = find(strcmpi(unique(description),CellPhenotypes.descriptions(i)));
 index{i} = strmatch(unique(description), CellPhenotypes.descriptions(i))
  end
  
%     phenoIDs = [phenoIDs uniqueCell];
%     mergePhenoID = mergePhenotypes(phenoIDs)
end
>>>>>>> local
>>>>>>> local
