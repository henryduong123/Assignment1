function [deplist, intDeps, callTree] = buildDepList(funcname)
    [deps,builtins,classes,prob_files,prob_sym,eval_strings,called_from] = depfun(funcname, '-quiet');
    
    internalIdx = strmatch(matlabroot, deps);
    intDeps = deps(internalIdx);
    
    tst = boolean(zeros(length(deps),1));
    tst(internalIdx) = 1;
    tst = ~tst;
    deplist = deps(tst);
    
    extCallFrom = called_from(tst);
    
end