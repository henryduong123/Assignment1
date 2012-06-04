function [iterations totalTime] = LinkFirstFrameTrees()
    global HashedCells
    
    iterations = 0;
    
    % Try to Push/reseg
    totalTime = 0;
    maxPushCount = 10;
    for i=1:maxPushCount
    	[assignExt findTime extTime] = Families.LinkTreesForward([HashedCells{1}.trackID]);
%         LogAction(['Tree inference step ' num2str(i)],[assignExt findTime extTime],[]);
        totalTime = totalTime + findTime + extTime;
        
        iterations = i;
        
        if ( assignExt == 0 )
            break;
        end
    end
    
%     LogAction('Completed Tree Inference', [i totalTime],[]);
end