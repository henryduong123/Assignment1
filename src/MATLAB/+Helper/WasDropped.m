% bool = WasDropped(track, list)
% Returns 1 or 0 depending if the track is in the given list

% ChangeLog:
% EW 6/8/12 created
function bool = WasDropped(track, list)
bool = 0;

if (~exist('track','var') || ~exist('list','var')), return; end

if (isempty(track) || isempty(list)), return; end

if (any(list(list==track)))
    bool = 1;
end
end

