function [hullID trackID] = GetClosestCell(allowEmpty)
hullID = FindHull(get(gca,'CurrentPoint'));
if(0>=hullID)
    if (allowEmpty )
        hullID = [];
    else
        warndlg('Please click closer to the center of the desired cell','Unknown Cell');
    end
    trackID = [];
    return
end
trackID = GetTrackID(hullID);

end