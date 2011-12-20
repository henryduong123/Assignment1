function fdeps = cpdeps(outdir, funcname)
    % Takes a long time
    fdeps = buildDepList(funcname);
    
    % Copy all external dependencies to specified path
    recmkdir(outdir);
    
    for i=1:length(fdeps)
        copyfile(fdeps{i}, outdir);
    end
end