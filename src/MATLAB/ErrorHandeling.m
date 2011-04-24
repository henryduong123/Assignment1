function ErrorHandeling(errorMessage, errStack)
%***Possibly Throws Error***
% ErrorHandeling(errorMessage) will attempt to fix the issue and log the
% error.  If unsuccessful, another log entery will be made and will throw
% the new error.

%--Eric Wait

global Figures

msgboxHandle = msgbox('Attempting to fix database. Will take some time depending on the size of the database. This window will close when done',...
    'Fixing Database','warn','modal');
LogAction(errorMessage,0,0,errStack);

%let the user know that this might take a while
set(Figures.tree.handle,'Pointer','watch');
set(Figures.cells.handle,'Pointer','watch');

try
    History('Top');
    TestDataIntegrity(1);
    msgbox('Database corrected. Your last action was undone, please try again. If change errors again, save the data file and then send it and the log to the code distributor.',...
        'Database Correct','help','modal');
catch errorMessage2
    %let the user know that it is done
    set(Figures.tree.handle,'Pointer','arrow');
    set(Figures.cells.handle,'Pointer','arrow');
    History('Top'); %reinstate the state prior to the change
    fprintf(['Orginal error:' errorMessage '\nSecond error:' errorMessage2.message '\n']);
    LogAction(['Unable to fix database -- ' errorMessage2.message],0,0,errorMessage2.stack);
    msgbox('Unable to fix database! Please save the data file and then send it and the log to the code distributor. Your last change did not take place!',...
        'Database ERROR','error');
    rethrow(errorMessage2)
end
close(msgboxHandle);

%let the user know that the drawing is done
set(Figures.tree.handle,'Pointer','arrow');
set(Figures.cells.handle,'Pointer','arrow');
end