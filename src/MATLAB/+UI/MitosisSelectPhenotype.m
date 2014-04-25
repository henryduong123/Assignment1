function [hullID trackID] = MitosisSelectPhenotype()
    global Figures MitosisEditStruct
    
    hullID = [];
    trackID = [];
    if ( isempty(MitosisEditStruct.selectedTrackID) )
        msgbox('No cells selected for mitosis or phenotype identification','No Cell Selected','warn');
        return;
    end
    
    trackID = MitosisEditStruct.selectedTrackID;
    
    currentPoint = UI.GetClickedCellPoint();
    [bErr hullID] = Editor.ReplayableEditAction(@Editor.MitosisHullPhenotypeAction, currentPoint, Figures.time, trackID);
    
    trackID = Hulls.GetTrackID(hullID);
end
