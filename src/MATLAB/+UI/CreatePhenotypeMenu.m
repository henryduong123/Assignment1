% CreatePhenotypeMenu()
% Initialize the phenotype portion of the context menu.

function CreatePhenotypeMenu()
    global Figures CellPhenotypes
    
    PhenoMenu = uimenu(Figures.cells.contextMenuHandle,...
        'Label',        'Phenotype',...
        'Separator',    'on',...
        'CallBack',     @updatePhenoCheck);
    
    % Initialize phenotype structure if necessary
    if isempty(CellPhenotypes) || ~isfield(CellPhenotypes,'descriptions')
        CellPhenotypes.descriptions={'died'};
        CellPhenotypes.contextMenuID=[];
        CellPhenotypes.hullPhenoSet = zeros(2,0);
    end

    UI.UpdatePhenotypeMenu(PhenoMenu);
end

% Whenever we right-click on a cell this puts a check mark next to active
% phenotype, if any.
function updatePhenoCheck(src, evnt)
    global CellPhenotypes
    
    [hullID trackID] = UI.GetClosestCell(0);
    if(isempty(trackID))
        return
    end
    
    phenoChildren = get(src, 'Children');
    
    for i=1:length(phenoChildren)
        set(phenoChildren, 'checked','off');
    end

    trackPheno = Tracks.GetTrackPhenotype(trackID);

    if ( trackPheno == 0 )
        return
    end
    
    childLabels = get(phenoChildren, 'Label');
    checkedIdx = find(strcmpi(CellPhenotypes.descriptions(trackPheno), childLabels),1);

    % Children are ordered when added in UpdatePhenotypeMenu, so can just
    % use the ordering to choose the check child.
    set(phenoChildren(checkedIdx), 'checked','on');
end
