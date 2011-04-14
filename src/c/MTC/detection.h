// Detection related types and variables
struct SDetection
{
	int X;
	int Y;
	int nPixels;
	int nConnectedHulls;
	std::vector<int>DarkConnectedHulls;
	std::vector<double>DarkConnectedCost;

	
};

// Read and initialize detection related data.  All globals listed below must be filled or initialized by the end of this routine.
// Globals:
//  rgDetect - filled with detection data
//  gNumFrames - length of rows of rgDetect
//  rgDetectLengths - the length of each column of rgDetect
//  rgDetectLengthSum - the cumulative sum of rgDetectLengths, rgDetectLengthSum[0] = 0, rgDetectLengthSum[1] = rgDetectLengths[0], etc.
//  gMaxDetections - maximum detections in any frame
//  gConnectOut,gConnectIn - initialized to numPts(total detections) empty std::maps each
//  gAssignedConnectIn - same size as gConnectIn, initialized to -1
//  gAssignedConnectOut - same as gAssignedConnectIn, these are for quick lookup of assigned paths
int ReadDetectionData(int argc, char* argv[]);