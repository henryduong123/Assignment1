//******************************************************
//
//    This file is part of LEVer.exe
//    (C) 2011 Andrew Cohen, Eric Wait and Mark Winter
//
//******************************************************

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

extern std::vector<tPathList> gAssignedTracklets;