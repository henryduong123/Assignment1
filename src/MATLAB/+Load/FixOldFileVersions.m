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
    global CONSTANTS CellHulls CellFamilies HashedCells ConnectedDist GraphEdits ResegLinks Costs CellPhenotypes CellTracks ReplayEditActions Log

    bNeedsUpdate = false;
    
    % File was created with an incorrectly compiled version string (force version 6.2)
    if ( ~Load.FileVersionGreaterOrEqual('1.0') )
        CONSTANTS.version = '6.2';
    end
    
    emptyHash = find(cellfun(@(x)(isempty(x)), HashedCells));
    if ( ~isempty(emptyHash) )
        for i=1:length(emptyHash)
            HashedCells{emptyHash(i)} = struct('hullID',{}, 'trackID',{});
        end
    end
    
    % As of version 7.13.3, channelOrder doesn't exist and primaryChannel indicates the main phase display/seg channel
    if ( isfield(CONSTANTS, 'channelOrder') )
        chanOrder = CONSTANTS.channelOrder;
        [~,invChanOrder] = sort(chanOrder);
        
        Load.ReplaceConstant('channelOrder', 'primaryChannel',chanOrder(1));
        
        % Put channel colors and fluorescent indicators in file name order
        chanColor = CONSTANTS.channelColor(invChanOrder,:);
        chanFluor = CONSTANTS.channelFluor(invChanOrder,:);
        
        Load.AddConstant('channelColor', chanColor, 1);
        Load.AddConstant('channelFluor', chanFluor, 1);
        
        bNeedsUpdate = true;
    end
    
    % As of version 7.11, add tag field for CellHulls
    if ( ~isfield(CellHulls, 'tag') )
        [CellHulls.tag] = deal('');
        bNeedsUpdate = true;
    end
    
    % As of version 7.9, remove imagePixels field
    if ( isfield(CellHulls, 'imagePixels') )
        Load.RemoveImagePixelsField();
        bNeedsUpdate = true;
    end
    
    % Need userEdited field as of ver 5.0
    if ( ~isfield(CellHulls, 'userEdited') )
        Load.AddUserEditedField();
        bNeedsUpdate = true;
    end
    
    % Remove HashedCells.editedFlag field as of ver 7.0
    if ( ~isempty(HashedCells) )
        for t=1:length(HashedCells)
            if ( isfield(HashedCells{t}, 'editedFlag') )
                HashedCells{t} = rmfield(HashedCells{t}, 'editedFlag');
                bNeedsUpdate = true;
            end
        end
    end
    
    if ( isempty(GraphEdits) )
        GraphEdits = sparse([], [], [], size(Costs,1), size(Costs,2), round(0.1*size(Costs,2)));
        bNeedsUpdate = true;
    end
    
    if ( isempty(ResegLinks) )
        ResegLinks = sparse([], [], [], size(Costs,1), size(Costs,2), round(0.1*size(Costs,2)));
        bNeedsUpdate = true;
    end

    % Calculate connected-component distance for all cell hulls (out 2 frames)
    if ( ~Load.FileVersionGreaterOrEqual('4.3') || isempty(ConnectedDist) )
        fprintf('\nBuilding Cell Distance Information...\n');
        ConnectedDist = [];
        Tracker.BuildConnectedDistance(1:length(CellHulls), 0, 1);
        fprintf('Finished\n');
        bNeedsUpdate = true;
    end
    
    % Remove CellTracks.phenotype field and use it to create hullPhenoSet
    % instead
    if ( ~Load.FileVersionGreaterOrEqual('5.0') || (~isfield(CellPhenotypes,'hullPhenoSet') && isfield(CellTracks,'phenotype') && isfield(CellTracks,'timeOfDeath')) )
        fprintf('\nConverting Phenotype information...\n');
        Load.UpdatePhenotypeInfo();
        fprintf('Finished\n');
        bNeedsUpdate = true;
    end
    
    % Add color field to phenotype structure as of ver 7.2
    if ( ~isfield(CellPhenotypes,'colors') )
        CellPhenotypes.colors = hsv(length(CellPhenotypes.descriptions));
        CellPhenotypes.colors(1,:) = [0 0 0];
        bNeedsUpdate = true;
    elseif ( iscell(CellPhenotypes.colors) )
        CellPhenotypes.colors = CellPhenotypes.colors{1};
        bNeedsUpdate = true;
    end
    
    % Will search older versions of the code for any variation of ambiguous
    % or off screen and replace them with 'ambiguous' or 'off screen' will
    % merge other ambiguous ones and create new code.
    if ( Load.FixDefaultPhenotypes() )
        bNeedsUpdate = true;
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
        
        bNeedsUpdate = true;
    end
    
    % Add in any missing "edit" fields for families
    bFamilyUpdate = Load.AddFamilyEditFields();
    bNeedsUpdate = (bNeedsUpdate || bFamilyUpdate);
    
    % Make sure that CellHulls userEdited, deleted
    % are all "logical". Also, CellFamilies.bLocked/bCompleted/bFrozen
    CellHulls = forceLogicalFields(CellHulls, 'userEdited','deleted');
    CellFamilies = forceLogicalFields(CellFamilies, 'bLocked', 'bCompleted', 'bFrozen');
    
    bEmptyHulls = arrayfun(@(x)(isempty(x.deleted)), CellHulls);
    emptyIdx = find(bEmptyHulls);
    for i=1:length(emptyIdx)
        CellHulls(emptyIdx(i)).deleted = true;
        CellHulls(emptyIdx(i)).userEdited = false;
    end
    
    % Get rid of all figure related handles in Log
    if(isfield(Log,'figures'))
        for i=1:length(Log)
            Log(i).frame = Log(i).figures.time;
        end
        Log = rmfield(Log,'figures');
        bNeedsUpdate = true;
    end
    
    % Make sure fields in CellFamilies are doubles
    for i=1:length(CellFamilies)
        CellFamilies(i).rootTrackID = double(CellFamilies(i).rootTrackID);
        CellFamilies(i).tracks = double(CellFamilies(i).tracks);
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

