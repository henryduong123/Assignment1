% Find a matrix A an optimal matching of stainPoints and phasePoints 
% minimizes ||stainPoints - phasePoints*A|| in the L2-norm.

function bestA = guessAffineTransform(phasePoints, stainPoints)
    global finalIm
    
    A = [];
    
%     hTestFig = figure();
%     imagesc(finalIm);
%     colormap(gray);
%     hold on;
%     plot(phasePoints(:,1), phasePoints(:,2), '.r');
%     plot(stainPoints(:,1), stainPoints(:,2), '.g');
    
    D = pdist2(phasePoints(:,[1 2]), stainPoints);
    maxDist = max(D(:)) / 4;
    
    bestA = [];
    bestDist = Inf;
    
    for reps=1:10
        rot = 2*pi*rand(1,1) - pi;
        scales = [1 1];
        trans = maxDist*rand(2,1);
        
        A = [scales(1) 0 0; 0 scales(2) 0; 0 0 1];
        A = A * [cos(rot) sin(rot) 0; -sin(rot) cos(rot) 0; 0 0 1];
        A = A * [1 0 0; 0 1 0; trans(1) trans(2) 1];
        
        for i=1:500
%             trnfPoints = [phasePoints ones(size(phasePoints,1),1)] * A;
%             
%             D = pdist2(trnfPoints(:,[1 2]), stainPoints);
%             D(D>300) = Inf;
%             [assignIdx assignDist] = assignmentoptimal(D);
% 
%             bCorrPoint = (assignIdx > 0);
%             assTrnfPoints = trnfPoints(bCorrPoint,[1 2]);
%             assStainPoints = stainPoints(assignIdx(bCorrPoint),:);
%             
%             deltaA = pinv([assTrnfPoints ones(size(assTrnfPoints,1),1)])*[assStainPoints ones(size(assStainPoints,1),1)];
            
            deltaXMatrix = repmat(trnfPoints(:,1),[1 size(stainPoints,1)])-repmat((stainPoints(:,1).'),[size(trnfPoints,1) 1]);
            deltaYMatrix = repmat(trnfPoints(:,2),[1 size(stainPoints,1)])-repmat((stainPoints(:,2).'),[size(trnfPoints,1) 1]);
            
            sigma = 100;
            assignPDF = (normcdf(deltaXMatrix+1,0,sigma)-normcdf(deltaXMatrix-1,0,sigma)) .* (normcdf(deltaYMatrix+1,0,sigma)-normcdf(deltaYMatrix-1,0,sigma));
            
            weightSum = sum(assignPDF,1);
            bAssignPoints = (weightSum ~= 0);
            
            sumX = sum(repmat(trnfPoints(:,1),[1 size(stainPoints,1)]) .* assignPDF,1);
            sumY = sum(repmat(trnfPoints(:,2),[1 size(stainPoints,1)]) .* assignPDF,1);
            
            meanSumX = ((sumX(:,bAssignPoints) ./ weightSum(bAssignPoints)).');
            meanSumY = ((sumY(:,bAssignPoints) ./ weightSum(bAssignPoints)).');
            
            deltaA = pinv([meanSumX meanSumY ones(size(meanSumX,1),1)])*[stainPoints(bAssignPoints,:) ones(nnz(bAssignPoints),1)];
            
            A = A * deltaA;
            
            if ( norm(deltaA-eye(3),'fro') < 0.001 )
                break;
            end
            
%             testPoints = [phasePoints ones(size(phasePoints,1),1)] * A;
%             for i=1:size(testPoints,1)
%                 plot([trnfPoints(i,1) testPoints(i,1)], [trnfPoints(i,2) testPoints(i,2)], '-r')
%             end
%             plot(testPoints(:,1), testPoints(:,2), 'rx');
        end
        
        trnfPoints = [phasePoints ones(size(phasePoints,1),1)] * A;
        
        D = pdist2(trnfPoints(:,[1 2]), stainPoints);
        D(D>300) = Inf;
        [assignIdx assignDist] = assignmentoptimal(D);
        
        if ( nnz(assignIdx) > 5 && bestDist > assignDist )
            bestDist = assignDist;
            bestA = A;
        end
    end
end
