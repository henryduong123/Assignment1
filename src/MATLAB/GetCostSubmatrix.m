%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
%     This file is part of LEVer.exe
%     (C) 2011 Andrew Cohen, Eric Wait and Mark Winter
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [costMatrix bOutAffected bInAffected] = GetCostSubmatrix(fromHulls, toHulls)
%     global Costs
%     inCostMatrix = Costs;
    inCostMatrix = GetCostMatrix();
    
    % Get costMatrix representing costs from fromHulls to toHulls
%     [r c] = ndgrid(fromHulls, toHulls);
%     costIdx = sub2ind(size(inCostMatrix), r, c);
%     costMatrix = full(inCostMatrix(costIdx));
    
    % Vectorized implementation of this code is commented out above
    % because we cannot use more than 46K square elements in a matrix in
    % 32-bit matlab.
    costMatrix = zeros(length(fromHulls),length(toHulls));
    for i=1:length(fromHulls)
        for j=1:length(toHulls)
            costMatrix(i,j) = inCostMatrix(fromHulls(i),toHulls(j));
        end
    end

    bInAffected = any(costMatrix,1);
    costMatrix = costMatrix(:,bInAffected);
    
    bOutAffected = any(costMatrix,2);
    costMatrix = full(costMatrix(bOutAffected,:));

    costMatrix(costMatrix == 0) = Inf;
end