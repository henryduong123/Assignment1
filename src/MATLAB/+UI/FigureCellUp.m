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
    trackID = Hulls.GetTrackID(currentHullID);
    
    bErr = Editor.ReplayableEditAction(@Editor.ContextSwapLabels, trackID, previousTrackID, Figures.time);
    if ( bErr )
        return;
    end
    
    Error.LogAction(['Swapped tracks ' num2str(trackID) ', ' num2str(previousTrackID) ' beginning at t=' num2str(Figures.time)], [],[]);
    
    previousTrackID = Hulls.GetTrackID(currentHullID);
    
    UI.DrawTree(CellTracks(previousTrackID).familyID);
elseif(CellTracks(previousTrackID).familyID~=Figures.tree.familyID)
    %no change and the current tree contains the cell clicked on
    UI.DrawTree(CellTracks(previousTrackID).familyID);
end


UI.DrawCells();
end