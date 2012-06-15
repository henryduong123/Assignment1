% FigureCellUp(src,evnt)

% ChangeLog:
% NLS 6/11/12 Created

function FigureCellUp(src,evnt)
global Figures CellTracks CellFamilies HashedCells

set(Figures.cells.handle,'WindowButtonUpFcn','');
if(Figures.cells.downHullID == -1)
    return
end

currentHullID = Hulls.FindHull(get(gca,'CurrentPoint'));
if ( currentHullID == -1 )
    currentHullID = Figures.cells.downHullID;
end
previousTrackID = Hulls.GetTrackID(Figures.cells.downHullID);

if(currentHullID~=Figures.cells.downHullID)
    try
        Tracker.GraphEditSetEdge(Hulls.GetTrackID(currentHullID),previousTrackID,Figures.time);
        Tracker.GraphEditSetEdge(previousTrackID,Hulls.GetTrackID(currentHullID),Figures.time);
        Tracks.SwapLabels(Hulls.GetTrackID(currentHullID),previousTrackID,Figures.time);
        Editor.History('Push')
    catch errorMessage
        Error.ErrorHandling(['SwapTrackLabels(' num2str(Figures.time) ' ' num2str(Hulls.GetTrackID(currentHullID))...
            ' ' num2str(previousTrackID) ') -- ' errorMessage.message],errorMessage.stack);
        return
    end
    
    Families.ProcessNewborns();
    previousTrackID = Hulls.GetTrackID(currentHullID);
    
    UI.DrawTree(CellTracks(previousTrackID).familyID);
elseif(CellTracks(previousTrackID).familyID~=Figures.tree.familyID)
    %no change and the current tree contains the cell clicked on
    UI.DrawTree(CellTracks(previousTrackID).familyID);
end


UI.DrawCells();
end