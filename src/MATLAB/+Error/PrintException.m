function excpString = PrintException(excp, prefixstr)
    if ( ~exist('prefixstr','var') )
        prefixstr = '  ';
    end
    
    excpString = sprintf('%sstacktrace: \n', prefixstr);
    numspaces = 5;
    stacklevel = 1;
    for i=length(excp.stack):-1:1
        fprintf('%s',prefixstr);
        excpString = [excpString sprintf('%s', prefixstr)];
        for j=1:numspaces
            excpString = [excpString ' '];
        end
        
        excpString = [excpString sprintf('%d.',stacklevel)];
        for j=1:stacklevel
            excpString = [excpString ' '];
        end
        
        [mfdir mfile mfext] = fileparts(excp.stack(i).file);
        
        excpString = [excpString sprintf('%s%s: %s(): %d\n', mfile, mfext, excp.stack(i).name, excp.stack(i).line)];
        
        stacklevel = stacklevel + 1;
    end
    
    excpString = [excpString sprintf('%smessage: %s\n',prefixstr,excp.message)];
end
