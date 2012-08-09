function [iterations totalTime] = LinkTrees(families)
    global CellFamilies
    
    iterations = 0;
    
    rootTrackIDs = [CellFamilies(families).rootTrackID];
    
    % Try to Push/reseg
    totalTime = 0;
    maxPushCount = 10;
    for i=1:maxPushCount
    	[assignExt findTime extTime] = Families.LinkTreesForward(rootTrackIDs);
%         LogAction(['Tree inference step ' num2str(i)],[assignExt findTime extTime],[]);
        totalTime = totalTime + findTime + extTime;
        
        iterations = i;
        
        if ( assignExt == 0 )
            break;
        end
    end
    
%     LogAction('Completed Tree Inference', [i totalTime],[]);
end