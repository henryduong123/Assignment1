function PrintException(fid, excp, prefixstr)
    if ( ~exist('prefixstr','var') )
        prefixstr = '  ';
    end
    
    fprintf(fid,'%s',prefixstr);
    fprintf(fid, 'stacktrace: \n');
    numspaces = 5;
    stacklevel = 1;
    for i=length(excp.stack):-1:1
        fprintf(fid,'%s',prefixstr);
        for j=1:numspaces
            fprintf(fid,' ');
        end
        
        fprintf(fid,'%d.',stacklevel);
        for j=1:stacklevel
            fprintf(fid,' ');
        end
        
        [mfdir mfile mfext] = fileparts(excp.stack(i).file);
        
        fprintf(fid, '%s%s: %s(): %d\n', mfile, mfext, excp.stack(i).name, excp.stack(i).line);
        
        stacklevel = stacklevel + 1;
    end
    fprintf(fid,'%s',prefixstr);
    fprintf(fid, 'message: %s\n', excp.message);
end