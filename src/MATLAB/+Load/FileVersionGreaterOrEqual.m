% FileVersionGreaterOrEqual.m - Checks if the version string in a LEVer file
% is greater than or equal to the current LEVer version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
%     Copyright 2011 Andrew Cohen, Eric Wait and Mark Winter
%
%     This file is part of LEVer - the tool for stem cell lineaging. See
%     https://pantherfile.uwm.edu/cohena/www/LEVer.html for details
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

function bGreatOrEqual = FileVersionGreaterOrEqual(minVerString)
    global CONSTANTS
    
    bGreatOrEqual = 0;
    
    if ( ~isfield(CONSTANTS,'version') )
        return;
    end
    
    numTok = regexp(minVerString, '(\d+)\.(\d+(?:\.\d+)?).*', 'tokens', 'once');
    if ( isempty(numTok) )
        return;
    end
    
    minVersion = parseVerString(minVerString);
    fileVersion = parseVerString(CONSTANTS.version);
    if ( isempty(minVersion) || isempty(fileVersion) )
        return;
    end
    
    % Sorts entries, if CONSTANTS.version is >= minVersion, then order will start with entry 1.
    [dump,order] = sortrows([minVersion; fileVersion]);
    
    if ( order(1) ~= 1 )
        return;
    end
    
    bGreatOrEqual = 1;
end

function versionVec = parseVerString(verString)
    versionVec = [];
    
    numTok = regexp(verString, '(\d+)\.(\d+(?:\.\d+)?).*', 'tokens', 'once');
    if ( isempty(numTok) )
        return;
    end
    
    versionVec = [str2double(numTok{1}) str2double(numTok{2})];
end

