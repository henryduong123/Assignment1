function SetRandomState(randState)
    globStream = RandStream.getGlobalStream();
    globStream.State = randState;
end
