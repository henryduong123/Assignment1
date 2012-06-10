
function figureCellUp(src,evnt)
global Figures CellTracks CellFamilies HashedCells

set(Figures.cells.handle,'WindowButtonUpFcn','');
if(Figures.cells.downHullID == -1)
    return
end

currentHullID = FindHull(get(gca,'CurrentPoint'));

if ( currentHullID == -1 )
    currentHullID = Figures.cells.downHullID;
end

previousTrackID = GetTrackID(Figures.cells.downHullID);

if(currentHullID ~= Figures.cells.downHullID)
    try
        GraphEditSetEdge(Figures.time,GetTrackID(currentHullID),previousTrackID);
        GraphEditSetEdge(Figures.time,previousTrackID,GetTrackID(currentHullID));
        SwapTrackLabels(Figures.time,GetTrackID(currentHullID),previousTrackID);
        History('Push')
    catch errorMessage
        try
            ErrorHandeling(['SwapTrackLabels(' num2str(Figures.time) ' ' num2str(GetTrackID(currentHullID))...
                ' ' num2str(previousTrackID) ') -- ' errorMessage.message],errorMessage.stack);
            return
        catch errorMessage2
            fprintf('%s',errorMessage2.message);
            return
        end
    end
    
    ProcessNewborns(1:length(CellFamilies),length(HashedCells));
    previousTrackID = GetTrackID(currentHullID);
    
elseif(CellTracks(previousTrackID).familyID==Figures.tree.familyID)
    %no change and the current tree contains the cell clicked on
    ToggleCellSelection(Figures.cells.downHullID);
    return
end

DrawTree(CellTracks(previousTrackID).familyID);
DrawCells();
ToggleCellSelection(Figures.cells.downHullID);
end