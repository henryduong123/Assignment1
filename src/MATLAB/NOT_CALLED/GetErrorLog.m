function errLog = GetErrorLog()
    global Log
    
    logs = (arrayfun(@(x)(sprintf('%s [%s]->[%s], %s %d\n', x.action,num2str(x.oldValue),num2str(x.newValue),x.stack(1).name,x.stack(1).line)),Log, 'UniformOutput',0));
    errLog = [logs{:}];
end