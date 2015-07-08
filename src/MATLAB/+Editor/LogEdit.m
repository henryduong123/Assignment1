function LogEdit(actionStr, inputIDs, outputIDs, bUserEdit)
    global EditList
    
    if ( ~exist('bUserEdit','var') )
        bUserEdit = true;
    end
    
    if ( ~exist('outputIDs','var') )
        outputIDs = [];
    end
    
    newEdit = struct('action',{actionStr}, 'bUserEdit',{bUserEdit}, 'input',{inputIDs}, 'output',{outputIDs});
    EditList = [EditList; newEdit];
end