% ReplayActionsFile(filename)

function ReplayActionsFile(filename)
    
    loadStruct = load(filename, 'ReplayEditActions');
    replayActions = loadStruct.ReplayEditActions;
    
    for i=1:length(replayActions)
        chkOut = cell(1,length(replayActions(i).ret));
        funcPtr = replayActions(i).funcPtr;
        funcArgs = replayActions(i).args;
        [bErr chkOut{:}] = Editor.ReplayableEditAction(funcPtr, funcArgs{:});
        
        if ( bErr ~= replayActions(i).bErr )
            fprintf('WARNING: Replaying action %d produced different result\n', i);
        end
    end
end