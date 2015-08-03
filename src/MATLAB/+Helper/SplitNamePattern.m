function [prefixString paramTokens postfixString] = SplitNamePattern(namePattern)
    prefixString = '';
    postfixString = '';
    
    paramTokens = Helper.GetNamePatternParams(namePattern);
    if ( isempty(paramTokens) )
        return;
    end
    
    paramStrings = cellfun(@(x)(['_' x{1} '%0' x{2} 'd']),paramTokens, 'UniformOutput',0);
    
    matchExpr = ['^(.+)' paramStrings{:} '(.*)$'];
    matchTok = regexp(namePattern, matchExpr, 'tokens','once');
    if ( isempty(matchTok) )
        paramTokens = {};
        return;
    end
    
    prefixString = matchTok{1};
    postfixString = matchTok{2};
end
