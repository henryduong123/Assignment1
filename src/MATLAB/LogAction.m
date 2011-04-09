function LogAction(action,oldValue,newValue)
%Log is used to keep track of what changes have been made.  It will
%append entries into a csv file to be opened in excel
%action = a string to represent what the action is.
%oldValue and newValue are used to show what numbers are changed. Please
%use the action string to denote what the values represent

global Figures CONSTANTS
time = clock;%[year month day hour minute seconds]

load('LEVerSettings.mat');

[x usr] = system('whoami');
ind = strfind(usr, '\');
usr = usr(:,ind+1:end-1);

row = [[num2str(time(1)) '/' num2str(time(2)) '/' num2str(time(3))] ','...
    [num2str(time(4)) ':' num2str(time(5)) ':' num2str(round(time(6)))] ',' usr ',,'...
    action ',' num2str(Figures.time) ','];
if(~isempty(oldValue))
    row = [row num2str(oldValue) ','];
else
    row = [row ','];
end
if(~isempty(newValue))
    row = [row num2str(newValue) '\n'];
else
    row = [row '\n'];
end

if (~exist([settings.matFilePath CONSTANTS.datasetName '_log.csv'],'file'))
    %add headers
    row = ['Date,Time,User,,Action,Frame,Old Value,New Value,\n' row];
end

file = fopen([settings.matFilePath CONSTANTS.datasetName '_log.csv'],'a');

fprintf(file,row);
fclose(file);

end
