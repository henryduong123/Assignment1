% Log is used to keep track of what changes have been made.  It will
% append entries into a csv file to be opened in excel
% action = a string to represent what the action is.
% oldValue and newValue are used to show what numbers are changed. Please
% use the action string to denote what the values represent

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

function LogAction(action,oldValue,newValue,callstack)

global Figures CONSTANTS Log
time = clock;%[year month day hour minute seconds]

settings = Load.ReadSettings();
if ( ~isempty(settings.matFilePath) )
    logPath = settings.matFilePath;
    logFile = fullfile(logPath, [CONSTANTS.datasetName '_log.csv']);
elseif ( isfield(CONSTANTS,'matFullFile') && ~isempty(CONSTANTS.matFullFile) )
    logPath = fileparts(CONSTANTS.matFullFile);
    logFile = fullfile(logPath, [CONSTANTS.datasetName '_log.csv']);
else
    logPath = '.\';
    logFile = fullfile(logPath, [CONSTANTS.datasetName '_log.csv']);
end

[x usr] = system('whoami');
ind = strfind(usr, '\');
usr = usr(:,ind+1:end-1);

if(~exist('oldValue','var'))
    oldValue = 0;
end
if(~exist('newValue','var'))
    newValue = 0;
end

if ( ~exist('callstack','var') )
    callstack = dbstack;
end

if(isempty(Figures) || ~isfield(Figures,'time'))
    figTime = -1;
else
    figTime = Figures.time;
end

row = [[num2str(time(1)) '/' num2str(time(2)) '/' num2str(time(3))] ','...
    [num2str(time(4)) ':' num2str(time(5)) ':' num2str(round(time(6)))] ',' usr ',,'...
    action ',' num2str(figTime) ','];
if(~isempty(oldValue))
    row = [row num2str(oldValue) ','];
else
    row = [row ','];
end
if(~isempty(newValue))
    row = sprintf('%s%s\n',row,num2str(newValue));
else
    row = sprintf('%s\n', row);
end

if (~exist(logFile,'file'))
    %add headers
    row = sprintf('Date,Time,User,,Action,Frame,Old Value,New Value,\n%s',row);
    if(~isempty(Log))
        row = reconstructLog(row);
    end
end

logEntry = length(Log)+1;

Log(logEntry).time = time;
Log(logEntry).user = usr;
Log(logEntry).stack = callstack;
Log(logEntry).action = action;
Log(logEntry).oldValue = oldValue;
Log(logEntry).newValue = newValue;
Log(logEntry).frame = figTime;

if ( ~exist(logFile,'file') )
    return;
end

file = fopen(logFile,'a');
while(file<2)
    answer = questdlg('Please close the log.','Log Opened','Use new log name','Try Again','Try Again');
    switch answer
        case 'Use new log name'
            file = fopen(fullfile(logPath,[CONSTANTS.datasetName '_log2.csv']),'a');
        case 'Try Again'
            file = fopen(logFile,'a');
    end
end

fprintf(file,'%s',row);
fclose(file);
end

function row = reconstructLog(row)
global Log

for i=1:length(Log)
    newRowString = [[num2str(Log(i).time(1)) '/' num2str(Log(i).time(2)) '/' num2str(Log(i).time(3))] ','...
        [num2str(Log(i).time(4)) ':' num2str(Log(i).time(5)) ':' num2str(round(Log(i).time(6)))] ',' Log(i).user ',,'...
        Log(i).action ',' num2str(Log(i).frame) ','];
    
    % This attempts to fix any character codes above 255, which generally
    % means that there's a Log Action which doesn't use num2str to convert
    % an ID to a string before concatenating.
    num2StrError = find(double(newRowString) > 255);
    if ( ~isempty(num2StrError) )
        cellStart = 1;
        cellStr = {};
        for k=1:length(num2StrError)
            cellStr = [cellStr {newRowString(cellStart:(num2StrError(k)-1))}];
            cellStr = [cellStr {num2str(double(newRowString(num2StrError(k))))}];
            cellStart = num2StrError(k)+1;
        end
        cellStr = [cellStr {newRowString(cellStart:end)}];
        newRowString = [cellStr{:}];
    end
    
    row = [row newRowString];
    
    if(~isempty(Log(i).oldValue))
        row = [row num2str(Log(i).oldValue) ','];
    else
        row = [row ','];
    end
    if(~isempty(Log(i).newValue))
        row = sprintf('%s%s\n',row,num2str(Log(i).newValue));
    else
        row = sprintf('%s\n',row);
    end
end
end
