% historyAction = ResegFinishAction()
% Edit Action:
% 
% Finish resegmentation action, (push history)

function [historyAction finishTime] = ResegFinishAction()
    global ResegState bResegPaused
    
    resegEdits = ResegState.SegEdits;
    save(['ResegEdits_' datestr(clock, 'yyyy-mm-dd_HHMM')], 'ResegState');
    
    finishTime = ResegState.currentTime;
    
    bResegPaused = [];
    ResegState = [];
    
    disp(['Finished Resegmentation: ' num2str(size(resegEdits,1)) ' automatic edits']);
    
    historyAction = '';
end
