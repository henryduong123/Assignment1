% [bErr varargout] = ReplayableEditAction(actPtr, varargin)
% 
% ReplayableEditAction attempts to execute the edit function pointed to by actPtr
% with the rest of the arguments to the function passed on unmodified. If
% an exception is caught during execution of the function an error is logged
% and the edit is undone.
%
% NOTE: All action function passed in actPtr are expected to return at
% least one argument, historyAction, which upon successful completion of
% the action, determines the appropriate history response (generally
% pushing to the history stack). See ChangeLabelAction for an example of
% this.
% 
% Regardless of success, the action and all arguments are added to the end
% of the replay list.

function [bErr varargout] = ReplayableEditAction(actPtr, varargin)
    global ReplayEditActions
    
    actCtx = getEditContext();
    
    newAct = struct('funcName',{func2str(actPtr)}, 'funcPtr',{actPtr}, 'args',{varargin},...
                    'ret',{{}}, 'histAct',{''}, 'bErr',{0}, 'ctx',{actCtx});
	
    if ( isempty(ReplayEditActions) )
        ReplayEditActions = newAct;
    else
        ReplayEditActions = [ReplayEditActions; newAct];
    end
    
    varargout = cell(1,max(0,nargout-1));
    [bErr historyAction varargout{:}] = Editor.SafeExecuteAction(actPtr, varargin{:});
    
    ReplayEditActions(end).bErr = bErr;
    if ( ~bErr )
        ReplayEditActions(end).ret = varargout;
        if ( ~isempty(historyAction) )
            Editor.History(historyAction);
            ReplayEditActions(end).histAct = historyAction;
        end
    end
end

function context = getEditContext()
    global Figures
    
    context = [];
    if ( isempty(Figures) )
        return;
    end
    
    curAx = get(Figures.cells.handle, 'CurrentAxes');
    cellLims = [xlim(curAx);ylim(curAx)];
    curAx = get(Figures.tree.handle, 'CurrentAxes');
    treeLims = [xlim(curAx);ylim(curAx)];
    
    context = struct('time',{Figures.time}, 'family',{Figures.tree.familyID}, 'treeLims',{treeLims}, 'cellLims',{cellLims});
end
