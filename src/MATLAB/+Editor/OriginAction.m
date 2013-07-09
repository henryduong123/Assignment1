% [coreHash bInitialSeg] = OriginAction(bInitialSeg)
% Edit Action:
%
% This initial action creates a hash of several core data structures to
% allow verification that a run of edits starts from the correct data.

function [historyAction coreHash bInitialSeg] = OriginAction(bInitialSeg)
    historyAction = '';
    coreHash = Dev.GetCoreHashList();
end