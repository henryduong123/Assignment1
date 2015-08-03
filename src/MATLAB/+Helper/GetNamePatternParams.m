function paramTokens = GetNamePatternParams(namePattern)
    paramTokens = regexp(namePattern, '_([a-zA-Z]{1,2})%0(\d+)d', 'tokens');
end