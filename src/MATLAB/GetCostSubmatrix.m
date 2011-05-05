%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
%     This file is part of LEVer.exe
%     (C) 2011 Andrew Cohen, Eric Wait and Mark Winter
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [costMatrix bOutAffected bInAffected] = GetCostSubmatrix(fromHulls, toHulls)
    global Costs
    
    % Get costMatrix representing costs from fromHulls to toHulls
    [r c] = ndgrid(fromHulls, toHulls);
    costIdx = sub2ind(size(Costs), r, c);
    costMatrix = full(Costs(costIdx));
    
    bInAffected = any(costMatrix,1);
    costMatrix = costMatrix(:,bInAffected);
    
    bOutAffected = any(costMatrix,2);
    costMatrix = full(costMatrix(bOutAffected,:));

    costMatrix(costMatrix == 0) = Inf;
end