//******************************************************
//
//    This file is part of LEVer.exe
//    (C) 2011 Andrew Cohen, Eric Wait and Mark Winter
//
//******************************************************



// Get cost based on a frame and index list.  The srcFrameIdx is used if there, it is the index into
// frame/index vectors of the source point(start of new path).  srcFrameIdx is trivially 0 if there is
// no history being used.
double GetCost(std::vector<int>& frame, std::vector<int>& index, int srcFrameIdx,int bCheck);