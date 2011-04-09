function ErrorHandeling(errorMessage)
%***Possibly Throws Error***
% ErrorHandeling(errorMessage) will attempt to fix the issue and log the
% error.  If unsuccessful, another log entery will be made and will throw
% the new error.

%--Eric Wait

global Figures

History('Pop');
History('Redo');%this is to get to the state just before the error, it was on the top of the stack

msgboxHandle = msgbox('Attempting to fix database. Will take some time depending on the size of the database. This window will close when done',...
    'Fixing Database','help','modal');
LogAction(errorMessage,[],[]);

%let the user know that this might take a while
set(Figures.tree.handle,'Pointer','watch');
set(Figures.cells.handle,'Pointer','watch');

try
    TestDataIntegrity(1);
    msgbox('Database corrected. Your last action was undone, please try again. If change errors again, save the data file and then send it and the log to the code distributor.',...
        'Database Correct','help','modal');
catch errorMessage2
    %let the user know that the drawing is done
    set(Figures.tree.handle,'Pointer','arrow');
    set(Figures.cells.handle,'Pointer','arrow');
    LogAction(['Unable to fix database -- ' errorMessage2.message],[],[]);
    msgbox('Unable to fix database! Please save the data file and then send it and the log to the code distributor. Your last change did not take place!',...
        'Database ERROR','error');
    rethrow(errorMessage2)
end
close(msgboxHandle);

%let the user know that the drawing is done
set(Figures.tree.handle,'Pointer','arrow');
set(Figures.cells.handle,'Pointer','arrow');
end