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
//
//***********************************************************************

#include <stdio.h>

#include <list>
#include <vector>
#include <limits>

#include "detection.h"
#include "cost.h"
#include "paths.h"

typedef std::list<CSourcePath*> tPathList;

//Detection related global variables
extern int gNumFrames;
extern int gnumPts;
extern int gMaxDetections;
extern int* rgDetectLengths;
extern int* rgDetectLengthSum;
extern SDetection** rgDetect;

//Path global variables
extern std::map<int,CSourcePath*>* gConnectOut;
extern std::map<int,CSourcePath*>* gConnectIn;

//For quick edge lookup from point (like inID/outID)
extern int* gAssignedConnectOut;
extern int* gAssignedConnectIn;
extern int* gAssignedTrackID;

//Global variables
extern int gWindowSize;
extern double gVMax;
extern double gCCMax;

extern std::vector<tPathList> gAssignedTracklets;