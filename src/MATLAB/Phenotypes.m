% added 4 19 2011 ac
function Phenotypes(src,evnt)

global Figures CellPhenotypes CellTracks

[hullID trackID] = GetClosestCell(0);
if(isempty(trackID)),return,end
% which did they click
for i=1:length(CellPhenotypes.contextMenuID)
    if src == CellPhenotypes.contextMenuID(i)
        break;
    end
end

if src~=CellPhenotypes.contextMenuID(i)
    % add new one
    NewPhenotype=inputdlg('Enter description for new phenotype','Cell Phenotypes');
    if isempty(NewPhenotype)
        return
    end
    
    AddPhenotype(NewPhenotype);
    
end
bActive = strcmp(get(CellPhenotypes.contextMenuID(i),'checked'),'on');
if 1==i
    % death!
    if CellTracks(trackID).phenotype
        set(CellPhenotypes.contextMenuID(CellTracks(trackID).phenotype),'checked','off');
    end
    if bActive
        CellTracks(trackID).phenotype=0;
    else
        CellTracks(trackID).phenotype=1;
    end
    
    if bActive || ~isempty(CellTracks(trackID).timeOfDeath )
        % turn off death...
        CellTracks(trackID).timeOfDeath = [];
        History('Push');
        try
            ProcessNewborns(CellTracks(trackID).familyID);
        catch errorMessage
            try
                ErrorHandeling(['ProcessNewborns(' num2str(trackID) ')-- ' errorMessage.message],errorMessage.stack);
                return
            catch errorMessage2
                fprintf('%s',errorMessage2.message);
                return
            end
        end
        LogAction(['Removed death for ' num2str(trackID)],[],[]);
        DrawTree(Figures.tree.familyID);
        DrawCells();
    else
        markDeath(src,evnt);       
    end 
    return
end

if bActive
    History('Push');
    set(CellPhenotypes.contextMenuID(CellTracks(trackID).phenotype),'checked','off');
    CellTracks(trackID).phenotype=0;
    LogAction(['Deactivated phenotype ' CellPhenotypes.descriptions{i} ' for track ' num2str(trackID)]);
else    
    History('Push');
    if CellTracks(trackID).phenotype        
        set(CellPhenotypes.contextMenuID(CellTracks(trackID).phenotype),'checked','off');
        LogAction(['Deactivated phenotype ' CellPhenotypes.descriptions{CellTracks(trackID).phenotype} ' for track ' num2str(trackID)]);
    end
    if 1==CellTracks(trackID).phenotype        
        CellTracks(trackID).timeOfDeath = [];
        DrawCells();
    end
    
    CellTracks(trackID).phenotype=i;
    set(CellPhenotypes.contextMenuID(CellTracks(trackID).phenotype),'checked','on');
    LogAction(['Activated phenotype ' CellPhenotypes.descriptions{i} ' for track ' num2str(trackID)]);

end
DrawTree(Figures.tree.familyID);   
    
end