
function [userEditCount resegEditCount userEditList resegEditList] = CountResegEdits()
    global ReplayEditActions
    
    userEditCount = 0;
    resegEditCount = 0;

    userEditList = {};
    resegEditList = {};
    
    %blockTypes = {'extra', 'reseg', 'user'};
    
    % Pretty much simulates the undo stacks, but with just edit counts
    typeStack = 1;
    stackEnds = 0;
    editStack = {{}};
    
    bInReseg = 0;
    for i=1:length(ReplayEditActions)
        
        if ( strcmpi(ReplayEditActions(i).funcName,'Editor.ResegInitializeAction') )
            bInReseg = 1;
            continue;
        end
        
        % TODO: Get reseg edits out here:
        if ( strcmpi(ReplayEditActions(i).funcName,'Editor.ResegFinishAction') )
            bInReseg = 0;
            
            numEdits = length(ReplayEditActions(i).ret{2}.SegEdits);
            
            newEdit = struct('count',{numEdits}, 'type',{typeStack(end)}, 'editFunc',{'ResegEdits'});
            editStack{end} = [editStack{end}(1:stackEnds(end)); {newEdit}];

            stackEnds(end) = stackEnds(end) + 1;
            continue;
        end
        
        % TODO: This is unfortunate, and I need it to really just not happen
        if ( bInReseg && strcmpi(ReplayEditActions(i).funcName,'Editor.InitHistory') )
            warning('RESEG:NoFinish', 'The current file was closed without finishing resegmentation process, edit counts may be inaccurate');
            return;
        end
        
        % Increase stack level and pick an edit type if a new subtask is started
        if ( strcmpi(ReplayEditActions(i).funcName,'Editor.StartReplayableSubtask') )
            typeStack = [typeStack 1];
            stackEnds = [stackEnds 0];
            editStack = [editStack; {{}}];
            
            if ( strcmpi(ReplayEditActions(i).args{1},'PauseResegTask') )
                typeStack(end) = 3;
            elseif ( strcmpi(ReplayEditActions(i).args{1},'InteractiveResegTask') )
                typeStack(end) = 2;
            end
            continue;
        end
        
        % Reduce stack level and add new edit block to level below (if not empty)
        if ( strcmpi(ReplayEditActions(i).funcName,'Editor.StopReplayableSubtask') )
            topStack = editStack{end};
            topEnd = stackEnds(end);
            
            stackEnds = stackEnds(1:(end-1));
            typeStack = typeStack(1:(end-1));
            editStack = editStack(1:(end-1));
            
            if ( topEnd > 0 )
                popEntry = topStack(1:topEnd,:);
                editStack{end} = [editStack{end}(1:stackEnds(end)); {popEntry}];
                stackEnds(end) = stackEnds(end) + 1;
            end
            continue;
        end
        
        % Just drop stack level by one
        if ( strcmpi(ReplayEditActions(i).funcName,'Editor.DropReplayableSubtask') )
            
            stackEnds = stackEnds(1:(end-1));
            typeStack = typeStack(1:(end-1));
            editStack = editStack(1:(end-1));
            
            if ( strcmpi(ReplayEditActions(i).args{1},'PauseResegTask') )
                bInPause = 0;
            end
            continue;
        end
        
        % Ignore these actions as they have no direct edit significance
        if ( strcmpi(ReplayEditActions(i).funcName,'Editor.ResegPlayAction') || strcmpi(ReplayEditActions(i).funcName,'Editor.ResegPauseAction') ...
                || strcmpi(ReplayEditActions(i).funcName,'Editor.ResegBackAction') || strcmpi(ReplayEditActions(i).funcName,'Editor.ResegPauseAction') ...
                || strcmpi(ReplayEditActions(i).funcName,'Editor.Top') )
            continue;
        end
        
        % Undo reduces current edit end by one
        if ( strcmpi(ReplayEditActions(i).funcName,'Editor.Undo') )
            if ( stackEnds(end) > 0 )
                stackEnds(end) = stackEnds(end) - 1;
            end
            
            continue;
        end
        
        % Redo increases current edit end by one
        if ( strcmpi(ReplayEditActions(i).funcName,'Editor.Redo') )
            if ( stackEnds(end) < size(editStack{end},1) )
                stackEnds(end) = stackEnds(end) + 1;
            end
            
            continue;
        end
        
        newEdit = struct('count',{1}, 'type',{typeStack(end)}, 'editFunc',{ReplayEditActions(i).funcName});
        editStack{end} = [editStack{end}(1:stackEnds(end)); {newEdit}];
        
        stackEnds(end) = stackEnds(end) + 1;
    end
    
    [resegEditCount resegEditList] = countAllEdits(editStack{1}, 2);
    [userEditCount userEditList] = countAllEdits(editStack{1}, 3);
end

function [editCount editList] = countAllEdits(editStack, editType)
    editCount = 0;
    editList = {};
    
    if ( isstruct(editStack) )
        if ( editType == editStack.type )
            editCount = editStack.count;
            editList = {editStack.editFunc};
        end
        
        return;
    end
    
    for i=1:length(editStack)
        [curCount curList] = countAllEdits(editStack{i}, editType);
        
        editCount = editCount + curCount;
        editList = [editList; curList];
    end
end
