function ReplaceConstant(curField, newField,newValue)
    global CONSTANTS
    
    if ( ~exist('newValue','var') )
        newValue = CONSTANTS.(curField);
    end
    
    constFields = fieldnames(CONSTANTS);
    curFieldIdx = find(strcmp(curField,constFields));
    
    newFieldIdx = find(strcmp(newField,constFields));
    if ( ~isempty(newFieldIdx) )
        constFields = constFields(setdiff(1:length(constFields),newFieldIdx));
    end
    
    constFields{curFieldIdx} = newField;
    
    CONSTANTS = rmfield(CONSTANTS, curField);
    CONSTANTS.(newField) = newValue;
    
    CONSTANTS = orderfields(CONSTANTS, constFields);
end
