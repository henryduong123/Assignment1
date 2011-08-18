//***********************************************************************
//
//    Copyright 2011 Andrew Cohen, Eric Wait and Mark Winter
// 
//    This file is part of LEVer - the tool for stem cell lineaging. See
//    https://pantherfile.uwm.edu/cohena/www/LEVer.html for details
// 
//    LEVer is free software: you can redistribute it and/or modify
//    it under the terms of the GNU General Public License as published by
//    the Free Software Foundation, either version 3 of the License, or
//    (at your option) any later version.
// 
//    LEVer is distributed in the hope that it will be useful,
//    but WITHOUT ANY WARRANTY; without even the implied warranty of
//    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the//    GNU General Public License for more details.
// 
//    You should have received a copy of the GNU General Public License
//    along with LEVer in file "gnu gpl v3.txt".  If not, see 
//    <http://www.gnu.org/licenses/>.

//
//***********************************************************************


//// Debug info about the cost function (can be left unused but must be defined)
//struct SDebugCostInfo
//{
//	double blurCost;
//	double linearityCost;
//	double localLinearityCost;
//	double cvSpeedCost;
//	double cvIntensity;
//	double dirCost;
//	double lowIntCost;
//	double lengthCost;
//	double forwardLengthCost;
//	double sizeCost;
//	bool bLeavesFrame;
//};

// Get cost based on a frame and index list.  The srcFrameIdx is used if there, it is the index into
// frame/index vectors of the source point(start of new path).  srcFrameIdx is trivially 0 if there is
// no history being used.
//double GetCost(std::vector<int>& frame, std::vector<int>& index, int srcFrameIdx, int bCheck = 1, SDebugCostInfo* pDbgInfo = NULL);
double getCost(std::vector<int>& path, int srcIdx, int bCheck = 1);

//// This routine is used during path discovery and possibly in GetCost to allow a short path if it appears
//// that the associated organelle is leaving the tracking window based on gExtents and the current path points
//// if this functionality is undesired the function should simply return false.
//bool CheckLeavesExtents(std::vector<int>& frame, std::vector<int>& index, int srcFrameIdx, SDetection* fakePt = NULL);
//
//// Write out debug cost info to file, can be empty function if not used
//void WriteDebugCostInfo(int argc, char* argv[], int argIdx);