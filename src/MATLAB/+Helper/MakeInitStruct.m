% newStruct = MakeInitStruct(outStruct, inStruct)

% Output a structure entry with fields same as outStruct and any fields
% with the same name copied from inStruct (all others empty)

function newStruct = MakeInitStruct(templateStruct, initStruct)
    if ( isempty(templateStruct) || isempty(fieldnames(templateStruct)) )
        error('Non-empty template structure required');
    end

    outFields = fieldnames(templateStruct);
    
    newStruct = struct();
    for i=1:length(outFields)
        if ( isfield(initStruct,outFields(i)) )
            newStruct.(outFields{i}) = initStruct.(outFields{i});
        else
            newStruct.(outFields{i}) = [];
        end
    end
end