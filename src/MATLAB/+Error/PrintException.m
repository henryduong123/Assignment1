
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
%     Copyright 2011-2016 Andrew Cohen
%
%     This file is part of LEVer - the tool for stem cell lineaging. See
%     http://n2t.net/ark:/87918/d9rp4t for details
% 
%     LEVer is free software: you can redistribute it and/or modify
%     it under the terms of the GNU General Public License as published by
%     the Free Software Foundation, either version 3 of the License, or
%     (at your option) any later version.
% 
%     LEVer is distributed in the hope that it will be useful,
%     but WITHOUT ANY WARRANTY; without even the implied warranty of
%     MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
%     GNU General Public License for more details.
% 
%     You should have received a copy of the GNU General Public License
%     along with LEVer in file "gnu gpl v3.txt".  If not, see 
%     <http://www.gnu.org/licenses/>.
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

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
