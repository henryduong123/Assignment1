
function SetDrawOrder(axHandle, handleOrder)
    curPools = get(axHandle,'UserData');
    
    curPools.renderOrder = [curPools.renderOrder; handleOrder(:)];
    
    set(axHandle, 'UserData',curPools);
end
