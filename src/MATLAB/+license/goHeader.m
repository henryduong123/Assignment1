
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
%     Copyright 2011-2016 Andrew Cohen, Eric Wait, Mark Winter, Walt
%     Mankowski
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


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
%     Copyright 2011-2016 Andrew Cohen, Eric Wait, Mark Winter, Walt
%     Mankowski
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

function goHeader(folder)
flist = dir(fullfile(folder, '*.m'));
for ff=1:length(flist)
    
    txt = license.getFileText(fullfile(folder,flist(ff).name));
    txtPreamble = license.getFileText('.\+license\LicenseHeader.m');
    
    idxPreamble = find(cellfun(@(x) ~isempty(strfind(x,'%%%%%%%%%%')),txt));
    if length(idxPreamble)~=2
        fprintf(1,'found file with no license: %s\n',flist(ff).name);
        % find the first non-comment line
        idxPreamble = find(cellfun(@(x) x(1)~='%',txt),1);
        if isempty(idxPreamble)
            continue
        end
        txtPreamble={ char(10), txtPreamble{:}, char(10)};
        
    else
        txt(idxPreamble(1):idxPreamble(2))=[];
    end
    
    txtRedone={txt{1:idxPreamble(1)-1} txtPreamble{:} txt{idxPreamble(1):end}};
    license.writeFileText(fullfile(folder,flist(ff).name),txtRedone);
end
