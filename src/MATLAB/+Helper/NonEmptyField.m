
function bHasNonempty = NonEmptyField(S, fieldname)
    bHasNonempty = (isfield(S,fieldname) && ~isempty(S.(fieldname)));
end