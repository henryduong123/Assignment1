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