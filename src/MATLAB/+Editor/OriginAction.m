% [coreHash bInitialSeg] = OriginAction(bInitialSeg)
% Edit Action:
%
% This initial action creates a has of several core data structures to
% allow verification that a run of edits starts from the correct data.

function [coreHash bInitialSeg] = OriginAction(bInitialSeg)
    coreHash = Dev.GetCoreHashList();
end