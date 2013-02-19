% CreateFluorescenceMenu()
% Initialize the fluorescence portion of the context menu.

function CreateFluorescenceMenu()
    global Figures FluorTypes
    
    FluorMenu = uimenu(Figures.cells.contextMenuHandle,...
        'Label',        'Fluorescence',...
        'Separator',    'on',...
        'CallBack',     @updateFluorCheck);
    
    % Initialize fluorescence structure if necessary
    if isempty(FluorTypes) || ~isfield(FluorTypes,'descriptions')
        FluorTypes.descriptions={'GFP'};
        FluorTypes.contextMenuID=[];
        FluorTypes.hullPhenoSet = zeros(2,0);
    end

    UI.UpdateFluorescenceMenu(FluorMenu);
end

function updateFluorCheck(src, evnt)
    global Figures FluorTypes CellTracks
    
    [hullID trackID] = UI.GetClosestCell(0);
    if(isempty(trackID))
        return
    end
    
    fluorChildren = get(src, 'Children');
    
    for i=1:length(fluorChildren)
        set(fluorChildren, 'checked','off');
    end
    
    idx = find(CellTracks(trackID).fluorTimes(1,:) == Figures.time);
    if (isempty(idx))
        return
    end
    
    fluorType = CellTracks(trackID).fluorTimes(2,idx);
    if (fluorType == 0)
        return;
    end
    
%    set(fluorChildren(fluorType+1), 'checked', 'on');
%     set(fluorChildren(2), 'checked', 'on');
    childLabels = get(fluorChildren, 'Label');
    checkedIdx = find(strcmp(FluorTypes.descriptions(fluorType), childLabels),1);

%     % Children are ordered when added in UpdatePhenotypeMenu, so can just
%     % use the ordering to choose the check child.
    set(fluorChildren(checkedIdx), 'checked','on');
end
