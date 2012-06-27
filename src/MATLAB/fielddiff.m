function idx = fielddiff(structA, structB, fieldname)
    chkfun = @(x,y)(xor(isempty(x.(fieldname)),isempty(y.(fieldname)) || (isempty(x.(fieldname)) && isempty(y.(fieldname))) && (any((x.(fieldname)~=y.(fieldname))))));
    idx = find(arrayfun(chkfun, structA, structB));
end