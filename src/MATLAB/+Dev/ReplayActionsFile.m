% ReplayActionsFile(filename)

function ReplayActionsFile(filename)
    
    loadStruct = load(filename, 'ReplayEditActions');
    replayActions = loadStruct.ReplayEditActions;
    
    if ( ~strcmpi(replayActions(1).funcName, 'OriginAction') )
        error('Replayable actions list does not specify origin data hash');
    end
    
    cmpHash = Dev.GetCoreHashList();
    coreHash = replayActions(1).ret{1};
    if ( ~all(strcmpi(cmpHash, coreHash)) )
        error('Current data does not match replay origin data hash.');
    end
    
    if ( replayActions(1).ret{2} == 0 )
        fprintf('WARNING: This data may not be initial segmentation data.\n');
    end
    
    for i=2:length(replayActions)
        chkOut = cell(1,length(replayActions(i).ret));
        funcPtr = replayActions(i).funcPtr;
        funcArgs = replayActions(i).args;
        [bErr chkHash chkOut{:}] = Dev.ReplayEditAction(funcPtr, funcArgs{:});
        
%         cmpHash = replayActions(i).chkHash;
%         if ( ~all(strcmpi(chkHash, cmpHash)) )
%             error('WARNING: Replaying action %d produced different core-hash\n', i);
%         end
        
        if ( bErr ~= replayActions(i).bErr )
            error('WARNING: Replaying action %d produced different result', i);
        end
    end
end