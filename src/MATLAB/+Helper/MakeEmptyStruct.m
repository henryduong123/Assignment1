% newStruct = MakeEmptyStruct(inStruct)
% Returns an empty struct based on the fields of inStruct

function newStruct = MakeEmptyStruct(inStruct)
outFields = fieldnames(inStruct);
newStruct = struct();

if isempty(inStruct)
    error('Non-empty struct required');
end

for i = 1:length(outFields)
    if islogical(inStruct(1).(outFields{i}))
        newStruct.(outFields{i}) = false;
    else
        newStruct.(outFields{i}) = [];
    end
end

end

