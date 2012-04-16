function LinkFirstFrameTrees()
    global CellHulls CellTracks HashedCells
    
    % Try to Push/reseg
    totalTime = 0;
    maxPushCount = 10;
    for i=1:maxPushCount
    	[assignExt findTime extTime] = LinkTreesForward([HashedCells{1}.trackID]);
        LogAction(['Tree inference step ' num2str(i)],[assignExt findTime extTime],[]);
        totalTime = totalTime + findTime + extTime;
        
        if ( assignExt == 0 )
            break;
        end
    end
    
    LogAction('Completed Tree Inference', [i totalTime],[]);

%     goodTrees = [];
%     for i=1:length(HashedCells{1})
%         trackID = HashedCells{1}(i).trackID;
%         familyID = CellTracks(trackID).familyID;
%         endTime = CellFamilies(familyID).endTime;
%         if ( endTime < length(HashedCells) )
%             continue;
%         end
%         
%         goodTracks = [goodTrees trackID];
%     end
%     ResegmentFromTree(goodTracks);
%     ExternalRetrack();
%     
%     for i=1:pushCount
%     	LinkTreesForward([HashedCells{1}.trackID]);
%     end
end