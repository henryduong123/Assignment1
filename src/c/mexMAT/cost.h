
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