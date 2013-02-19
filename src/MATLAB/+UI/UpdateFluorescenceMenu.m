% UpdatePhenotypeMenu(phenoMenu)
% Uses current list of fluorescence descriptions to build the associated
% context menu.

function UpdateFluorescenceMenu(fluorMenu)
    global Figures FluorTypes
    
    if ( ~exist('fluorMenu', 'var') )
        % Find phenotype menu handle
        contextMenu = Figures.cells.contextMenuHandle;
        ctxChildren = get(contextMenu, 'Children');
        
        childLabels = get(ctxChildren, 'Label');
        fluorMenuIdx = find(strcmpi('Fluorescence', childLabels),1);
        
        if ( isempty(fluorMenuIdx) )
            return;
        end

        fluorMenu = ctxChildren(fluorMenuIdx);
    end
    
    fluors = get(fluorMenu, 'Children');
    
    delete(fluors);
    
    uimenu(fluorMenu,...
        'Label',        'Create new fluorescence type...',...
        'UserData',     0,...
        'CallBack',     @setFluorType);
    
    for i=1:length(FluorTypes.descriptions)
        uimenu(fluorMenu,...
            'Label', FluorTypes.descriptions{i},...
            'UserData', i,...
            'CallBack', @setFluorType);
    end
end

function setFluorType(src, evnt)
    global Figures FluorTypes

    [hullID trackID] = UI.GetClosestCell(0);
    if(isempty(trackID))
        return
    end
    
    clickFluor = get(src, 'UserData');
    
    if ( clickFluor < 0 || clickFluor > length(FluorTypes.descriptions) )
        return;
    end
    
    bActive = strcmp(get(src, 'checked'),'on');
    
    if ( clickFluor == 0 )
        newDescription=inputdlg('Enter description for new fluorescence type','Fluorescence Types');
        if isempty(newDescription)
            return
        end
        
        [bErr clickFluor] = Editor.ReplayableEditAction(@Editor.AddFluorType, newDescription);
        if ( bErr )
            return;
        end
    end
    
    bErr = Editor.ReplayableEditAction(@Editor.ContextSetFluorescence, trackID, clickFluor, bActive);
    if (bErr)
        return;
    end
%     
%     bErr = Editor.ReplayableEditAction(@Editor.ContextSetPhenotype, hullID,clickPheno,bActive);
%     if ( bErr )
%         return;
%     end
%     
    if ( bActive )
        Error.LogAction(['Clear fluor type for ' num2str(trackID)]);
    else
        Error.LogAction(['Set fluor type for ' num2str(trackID) ' to ' clickFluor]);
    end
    
    UI.DrawTree(Figures.tree.familyID);
    UI.DrawCells();
end
