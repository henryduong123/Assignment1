% newStruct = MakeInitStruct(outStruct, inStruct)

% Output a structure entry with fields same as outStruct and any fields
% with the same name copied from inStruct (all others empty)

function newStruct = MakeInitStruct(templateStruct, initStruct)
    if ( isempty(fieldnames(templateStruct)) )
        error('Template structure must have at least one field');
    end

    outFields = fieldnames(templateStruct);
    
    % If this isn't an empty structure, then we can force logical fields
    bLogical = false(1,length(outFields));
    if ( ~isempty(templateStruct) )
        bLogical = structfun(@(x)(islogical(x)), templateStruct(1));
    end
    
    newStruct = struct();
    for i=1:length(outFields)
        if ( ~bLogical(i) )
            if ( isfield(initStruct,outFields(i)) )
                newStruct.(outFields{i}) = initStruct.(outFields{i});
            else
                newStruct.(outFields{i}) = [];
            end
        else
            if ( isfield(initStruct,outFields(i)) )
                newStruct.(outFields{i}) = forceLogical(initStruct.(outFields{i}));
            else
                newStruct.(outFields{i}) = false;
            end
        end
    end
end

function bValue = forceLogical(value)
    bValue = (value ~= 0);
end