function randState = GetRandomState()
    globStream = RandStream.getGlobalStream();
    randState = globStream.State;
end
