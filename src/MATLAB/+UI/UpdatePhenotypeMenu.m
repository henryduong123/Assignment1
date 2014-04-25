% UpdatePhenotypeMenu(phenoMenu)
% Uses current list of phenotype descriptions to build the associated
% context menu.

function UpdatePhenotypeMenu(phenoMenu)
    global Figures CellPhenotypes
    
    if ( isempty(Figures) )
        return;
    end
    
    if ( ~exist('phenoMenu', 'var') )
        % Find phenotype menu handle
        contextMenu = Figures.cells.contextMenuHandle;
        ctxChildren = get(contextMenu, 'Children');
        
        childLabels = get(ctxChildren, 'Label');
        phenoMenuIdx = find(strcmpi('Phenotype', childLabels),1);
        
        if ( isempty(phenoMenuIdx) )
            return;
        end

        phenoMenu = ctxChildren(phenoMenuIdx);
    end
    
    phenos = get(phenoMenu, 'Children');
    
    delete(phenos);
    
    uimenu(phenoMenu,...
        'Label',        'Create new phenotype...',...
        'UserData',     0,...
        'CallBack',     @setPhenotype);

      for i=1:length(CellPhenotypes.descriptions)
         uimenu(phenoMenu,...
            'Label', CellPhenotypes.descriptions{i},...
             'UserData', i,...
             'CallBack', @setPhenotype);
      end

end

function setPhenotype(src, evnt)
    global Figures CellPhenotypes

    if ( strcmpi(Figures.cells.editMode, 'mitosis') )
        [hullID trackID] = UI.MitosisSelectPhenotype();
    else
        [hullID trackID] = UI.GetClosestCell(0);
        if(isempty(trackID))
            return
        end
    end
    
    clickPheno = get(src, 'UserData');
    
    if ( clickPheno < 0 || clickPheno > length(CellPhenotypes.descriptions) )
        return;
    end
    
    bActive = strcmp(get(src, 'checked'),'on');
    
    if ( clickPheno == 0 )
        newDescription=inputdlg('Enter description for new phenotype','Cell Phenotypes');
        if isempty(newDescription)
            return
        end
        
        [bErr clickPheno] = Editor.ReplayableEditAction(@Editor.AddPhenotype, newDescription);
        if ( bErr )
            return;
        end
    end
    
    bErr = Editor.ReplayableEditAction(@Editor.ContextSetPhenotype, hullID,clickPheno,bActive);
    if ( bErr )
        return;
    end
    
    if ( bActive )
        Error.LogAction(['Clear phenotype for ' num2str(trackID)]);
    else
        Error.LogAction(['Set phenotype for ' num2str(trackID) ' to ' CellPhenotypes.descriptions{clickPheno}]);
    end
    
    UI.DrawTree(Figures.tree.familyID);
    UI.DrawCells();
end
