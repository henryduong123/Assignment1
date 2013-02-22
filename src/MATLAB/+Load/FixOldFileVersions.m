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
    global CellHulls CellFamilies HashedCells ConnectedDist GraphEdits Costs CellPhenotypes CellTracks ReplayEditActions Log

    bNeedsUpdate = 0;
    
    emptyHash = find(cellfun(@(x)(isempty(x)), HashedCells));
    if ( ~isempty(emptyHash) )
        for i=1:length(emptyHash)
            HashedCells{emptyHash(i)} = struct('hullID',{}, 'trackID',{});
        end
    end
   
    % Add imagePixels field to CellHulls structure (and resave in place)
    if ( ~isfield(CellHulls, 'imagePixels') )
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
    if ( ~isempty(HashedCells) && isfield(HashedCells{1}, 'editedFlag') )
        for t=1:length(HashedCells)
            HashedCells{t} = rmfield(HashedCells{t}, 'editedFlag');
        end
        bNeedsUpdate = 1;
    end
    
    if ( isempty(GraphEdits) )
        GraphEdits = sparse([], [], [], size(Costs,1), size(Costs,2), round(0.1*size(Costs,2)));
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
    
    % Adds the special origin action, to indicate that this is initial
    % segmentation data from which edit actions are built.
    if ( isempty(ReplayEditActions) || bNeedsUpdate )
        Editor.ReplayableEditAction(@Editor.OriginAction, 1);
        bNeedsUpdate = 1;
    end
    
    % Add bLockedField if necessary
    if ( ~isfield(CellFamilies, 'bLocked') )
        Load.AddLockedField();
        bNeedsUpdate = 1;
    end
    
    for i=1:length(Log)
        if(isfield(Log(i),'figures'))
            if(isfield(Log(i).figures,'advanceTimerHandle'))
                Log(i).figures.advanceTimerHandle = [];
            end
        end
    end
end