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

#include "mexIntegrityCheck.h"

#include <vector>
#include <map>
#include <set>

#define ARRAY_SIZE(x) (sizeof(x) / sizeof((x)[0]))

// Globals


// Matlab Globals
const mxArray* gCellHulls;
const mxArray* gCellTracks;
const mxArray* gCellFamilies;
const mxArray* gHashHulls;
const mxArray* gCellPhenotypes;

typedef std::pair<mwIndex, std::string> tErrorPair;
typedef std::map<mwIndex, std::string> tErrorList;

tErrorList gFamilyErrors;
tErrorList gTrackErrors;
tErrorList gHullErrors;
tErrorList gHashErrors;

const int errBufSize = 256;

// Rather long function but verifies correct field sizes for each track
bool checkTrackSizes(mwIndex trackID)
{
	mxArray* startTime = mxGetField(gCellTracks, C_IDX(trackID), "startTime");
	mxArray* endTime = mxGetField(gCellTracks, C_IDX(trackID), "endTime");
	mxArray* familyID = mxGetField(gCellTracks, C_IDX(trackID), "familyID");
	mxArray* hulls = mxGetField(gCellTracks, C_IDX(trackID), "hulls");

	mxArray* parentTrack = mxGetField(gCellTracks, C_IDX(trackID), "parentTrack");
	mxArray* siblingTrack = mxGetField(gCellTracks, C_IDX(trackID), "siblingTrack");
	mxArray* childrenTracks = mxGetField(gCellTracks, C_IDX(trackID), "childrenTracks");

	mwSize startTimeSz = mxGetNumberOfElements(startTime);
	if ( startTimeSz == 0 )
	{
		std::string nonemptyFields;
		if ( mxGetNumberOfElements(endTime) != 0 )
			nonemptyFields = "endTime ";

		if ( mxGetNumberOfElements(familyID) != 0 )
			nonemptyFields = nonemptyFields.append("familyID ");

		if ( mxGetNumberOfElements(hulls) != 0 )
			nonemptyFields = nonemptyFields.append("hulls ");

		if ( mxGetNumberOfElements(parentTrack) != 0 )
			nonemptyFields = nonemptyFields.append("parentTrack ");

		if ( mxGetNumberOfElements(siblingTrack) != 0 )
			nonemptyFields = nonemptyFields.append("siblingTrack ");

		if ( mxGetNumberOfElements(childrenTracks) != 0 )
			nonemptyFields = nonemptyFields.append("childrenTracks ");

		if ( nonemptyFields.length() > 0 )
		{
			char errMsg[errBufSize];
			sprintf(errMsg, "Empty track has non-empty fields: %s", nonemptyFields.c_str());
			gTrackErrors.insert(tErrorPair(C_IDX(trackID), errMsg));
			return false;
		}
	}
	else
	{
		std::string emptyFields;

		mwSize endTimeSz = mxGetNumberOfElements(endTime);
		if ( endTimeSz == 0 )
			emptyFields = "endTime ";

		mwSize familyIDSz = mxGetNumberOfElements(familyID);
		if ( familyIDSz == 0 )
			emptyFields = emptyFields.append("familyID ");

		mwSize hullsSz = mxGetNumberOfElements(hulls);
		if ( hullsSz == 0 )
			emptyFields = emptyFields.append("hulls ");

		if ( emptyFields.length() > 0 )
		{
			char errMsg[errBufSize];
			sprintf(errMsg, "Non-empty track has invalid empty fields: %s", emptyFields.c_str());
			gTrackErrors.insert(tErrorPair(C_IDX(trackID), errMsg));
			return false;
		}

		std::string invalidSizes;
		if ( startTimeSz != 1 )
			invalidSizes = "startTime ";

		if ( endTimeSz != 1 )
			invalidSizes = invalidSizes.append("endTime ");

		if ( familyIDSz != 1 )
			invalidSizes = invalidSizes.append("familyID ");

		mwSize parentTrackSz = mxGetNumberOfElements(parentTrack);
		if ( (parentTrackSz != 0) && (parentTrackSz != 1) )
			invalidSizes = invalidSizes.append("parentTrack ");

		mwSize siblingTrackSz = mxGetNumberOfElements(siblingTrack);
		if ( (siblingTrackSz != 0) && (siblingTrackSz != 1) )
			invalidSizes = invalidSizes.append("siblingTrack ");

		mwSize childrenTracksSz = mxGetNumberOfElements(childrenTracks);
		if ( (childrenTracksSz != 0) && (childrenTracksSz != 2) )
			invalidSizes = invalidSizes.append("childrenTracks ");

		if ( invalidSizes.length() > 0 )
		{
			char errMsg[errBufSize];
			sprintf(errMsg, "Non-empty track has fields of invalid size: %s", invalidSizes.c_str());
			gTrackErrors.insert(tErrorPair(C_IDX(trackID), errMsg));
			return false;
		}

		if ( (parentTrackSz == 1) && (siblingTrackSz == 0) )
		{
			gTrackErrors.insert(tErrorPair(C_IDX(trackID), "Track has parent ID but no sibling ID"));
			return false;
		}

		if ( (parentTrackSz == 0) && (siblingTrackSz == 1) )
		{
			gTrackErrors.insert(tErrorPair(C_IDX(trackID), "Track has sibling ID but no parent ID"));
			return false;
		}
	}

	return true;
}

// Rather long function but verifies correct field sizes for each family
bool checkFamilySizes(mwIndex familyID)
{
	mxArray* startTime = mxGetField(gCellFamilies, C_IDX(familyID), "startTime");
	mxArray* endTime = mxGetField(gCellFamilies, C_IDX(familyID), "endTime");
	mxArray* rootTrackID = mxGetField(gCellFamilies, C_IDX(familyID), "rootTrackID");
	mxArray* tracks = mxGetField(gCellFamilies, C_IDX(familyID), "tracks");

	mwSize startTimeSz = mxGetNumberOfElements(startTime);
	if ( startTimeSz == 0 )
	{
		std::string nonemptyFields;

		if ( mxGetNumberOfElements(endTime) != 0 )
			nonemptyFields = "endTime ";

		if ( mxGetNumberOfElements(rootTrackID) != 0 )
			nonemptyFields = nonemptyFields.append("rootTrackID ");

		if ( mxGetNumberOfElements(tracks) != 0 )
			nonemptyFields = nonemptyFields.append("tracks ");

		if ( nonemptyFields.length() > 0 )
		{
			char errMsg[errBufSize];
			sprintf(errMsg, "Empty family has non-empty fields: %s", nonemptyFields.c_str());
			gFamilyErrors.insert(tErrorPair(C_IDX(familyID), errMsg));
			return false;
		}
	}
	else
	{
		std::string emptyFields;

		mwSize endTimeSz = mxGetNumberOfElements(endTime);
		if ( endTimeSz == 0 )
			emptyFields = "endTime ";

		mwSize rootTrackIDSz = mxGetNumberOfElements(rootTrackID);
		if ( rootTrackIDSz == 0 )
			emptyFields = emptyFields.append("rootTrackID ");

		mwSize tracksSz = mxGetNumberOfElements(tracks);
		if ( tracksSz == 0 )
			emptyFields = emptyFields.append("tracks ");

		if ( emptyFields.length() > 0 )
		{
			char errMsg[errBufSize];
			sprintf(errMsg, "Non-empty family has invalid empty fields: %s", emptyFields.c_str());
			gFamilyErrors.insert(tErrorPair(C_IDX(familyID), errMsg));
			return false;
		}

		std::string invalidSizes;
		if ( startTimeSz != 1 )
			invalidSizes = "startTime ";

		if ( endTimeSz != 1 )
			invalidSizes = invalidSizes.append("endTime ");

		if ( rootTrackIDSz != 1 )
			invalidSizes = invalidSizes.append("rootTrackID ");

		if ( invalidSizes.length() > 0 )
		{
			char errMsg[errBufSize];
			sprintf(errMsg, "Non-empty family has fields of invalid size: %s", invalidSizes.c_str());
			gTrackErrors.insert(tErrorPair(C_IDX(familyID), errMsg));
			return false;
		}

		mwIndex rootTrackData = (mwIndex) mxGetScalar(rootTrackID);


		bool bFoundRoot = false;
		double* tracksData = mxGetPr(tracks);
		for ( int i=0; i < tracksSz; ++i )
		{
			if ( MATLAB_IDX((mwIndex) tracksData[i]) == MATLAB_IDX(rootTrackData) )
			{
				bFoundRoot = true;
				break;
			}
		}

		if ( !bFoundRoot )
		{
			gTrackErrors.insert(tErrorPair(C_IDX(familyID), "Root track of family is not in family's track list"));
			return false;
		}
	}

	return true;
}

bool checkTrackFamilyReferences(mwIndex familyID, std::vector<int>& trackRefCount)
{
	mxArray* rootTrackID = mxGetField(gCellFamilies, C_IDX(familyID), "rootTrackID");
	mxArray* tracks = mxGetField(gCellFamilies, C_IDX(familyID), "tracks");

	mwIndex familyStartTime = (mwIndex) mxGetScalar(mxGetField(gCellFamilies, C_IDX(familyID), "startTime"));
	mwIndex familyEndTime = (mwIndex) mxGetScalar(mxGetField(gCellFamilies, C_IDX(familyID), "endTime"));

	bool bCorrectEndTime = false;
	mwSize numTracks = mxGetNumberOfElements(tracks);
	double* trackData = mxGetPr(tracks);
	for ( mwSize i=0; i < numTracks; ++i )
	{
		mwIndex matTrackID = (mwIndex) trackData[i];

		if ( MATLAB_IDX(matTrackID) >= mxGetNumberOfElements(gCellTracks) )
		{
			gFamilyErrors.insert(tErrorPair(C_IDX(familyID), "Family track list contains trackID larger than CellTracks"));
			return false;
		}

		++trackRefCount[MATLAB_IDX(matTrackID)];

		if ( gTrackErrors.count(MATLAB_IDX(matTrackID)) > 0 )
		{
			//char errMsg[errBufSize];
			//sprintf(errMsg, "Track ID %d of family contains errors", matTrackID);
			//gFamilyErrors.insert(tErrorPair(C_IDX(familyID), errMsg));
			continue;
		}

		mxArray* trackFamily = mxGetField(gCellTracks, MATLAB_IDX(matTrackID), "familyID");
		if ( mxGetNumberOfElements(trackFamily) == 0 )
		{
			char errMsg[errBufSize];
			sprintf(errMsg, "Track ID %d in family is empty", matTrackID);
			gFamilyErrors.insert(tErrorPair(C_IDX(familyID), errMsg));
			return false;
		}

		mwIndex matTrackFamilyID = (mwIndex) mxGetScalar(trackFamily);
		if ( MATLAB_IDX(matTrackFamilyID) >= mxGetNumberOfElements(gCellFamilies) )
		{
			char errMsg[errBufSize];
			sprintf(errMsg, "Track ID %d in family has family ID larger than CellFamilies", matTrackID);
			gFamilyErrors.insert(tErrorPair(C_IDX(familyID), errMsg));
			return false;
		}

		if ( MATLAB_IDX(matTrackFamilyID) != C_IDX(familyID) )
		{
			char errMsg[errBufSize];
			sprintf(errMsg, "Track ID %d in family has family ID of %d, should be %d", matTrackID, matTrackFamilyID, (familyID+1));
			gFamilyErrors.insert(tErrorPair(C_IDX(familyID), errMsg));
			return false;
		}

		mwIndex trackEndTime = mxGetScalar(mxGetField(gCellTracks, MATLAB_IDX(matTrackID), "endTime"));
		if ( trackEndTime == familyEndTime )
			bCorrectEndTime = true;
	}

	// Verify that rootTrack has no parent track
	mwIndex matRootTrackID = (mwIndex) mxGetScalar(rootTrackID);
	if ( gTrackErrors.count(MATLAB_IDX(matRootTrackID)) > 0 )
	{
		//gFamilyErrors.insert(tErrorPair(C_IDX(familyID), "Root track of family contains errors"));
		return false;
	}

	mxArray* rootTrackParent = mxGetField(gCellTracks, MATLAB_IDX(matRootTrackID), "parentTrack");
	if ( mxGetNumberOfElements(rootTrackParent) > 0 )
	{
		char errMsg[errBufSize];
		sprintf(errMsg, "Root track %d of family %d has non-empty parent track", matRootTrackID, (familyID+1));
		gFamilyErrors.insert(tErrorPair(C_IDX(familyID), errMsg));
		//gTrackErrors.insert(tErrorPair(MATLAB_IDX(matRootTrackID), errMsg));
		return false;
	}

	mwIndex rootStartTime = (mwIndex) mxGetScalar(mxGetField(gCellTracks, MATLAB_IDX(matRootTrackID), "startTime"));
	if ( rootStartTime != familyStartTime )
	{
		char errMsg[errBufSize];
		sprintf(errMsg, "Family start time does not match start time of root track %d", matRootTrackID);
		gFamilyErrors.insert(tErrorPair(C_IDX(familyID), errMsg));
		return false;
	}

	if ( !bCorrectEndTime )
	{
		gFamilyErrors.insert(tErrorPair(C_IDX(familyID), "Family end time does not match any track end time"));
		return false;
	}

	return true;
}

bool checkParentChildReferences(mwIndex trackID)
{
	mxArray* parentTrack = mxGetField(gCellTracks, C_IDX(trackID), "parentTrack");
	mxArray* siblingTrack = mxGetField(gCellTracks, C_IDX(trackID), "siblingTrack");

	bool bNoParent = mxGetNumberOfElements(parentTrack) == 0;
	bool bNoSibling = mxGetNumberOfElements(siblingTrack) == 0;
	// If track has no parent or sibling, that's valid
	if ( bNoParent && bNoSibling )
		return true;

	mwIndex matParentID = (mwIndex) mxGetScalar(parentTrack);
	mwIndex matSiblingID = (mwIndex) mxGetScalar(siblingTrack);

	if ( MATLAB_IDX(matParentID) >= mxGetNumberOfElements(gCellTracks) )
	{
		gTrackErrors.insert(tErrorPair(C_IDX(trackID), "Track parent ID is larger than size of CellTracks"));
		return false;
	}

	if ( MATLAB_IDX(matParentID) >= mxGetNumberOfElements(gCellTracks) )
	{
		gTrackErrors.insert(tErrorPair(C_IDX(trackID), "Track sibling ID is larger than size of CellTracks"));
		return false;
	}

	// Check if linking to a track that already has errors
	if ( gTrackErrors.count(MATLAB_IDX(matParentID)) > 0 )
	{
		//gTrackErrors.insert(tErrorPair(C_IDX(trackID), "Track links to broken parent"));
		return false;
	}

	if ( gTrackErrors.count(MATLAB_IDX(matSiblingID)) > 0 )
	{
		//gTrackErrors.insert(tErrorPair(C_IDX(trackID), "Track links to broken sibling"));
		return false;
	}


	// Check for parent->child and sibling consistency
	mxArray* parentsChildren = mxGetField(gCellTracks, MATLAB_IDX(matParentID), "childrenTracks");
	if ( mxGetNumberOfElements(parentsChildren) == 0 )
	{
		char errMsg[errBufSize];
		sprintf(errMsg, "Track's parent %d has empty child list", matParentID);
		gTrackErrors.insert(tErrorPair(C_IDX(trackID), errMsg));
		return false;
	}

	int childTrackIdx = 0;
	double* childData = mxGetPr(parentsChildren);

	if ( (MATLAB_IDX((mwIndex) childData[0]) >= mxGetNumberOfElements(gCellTracks)) || (MATLAB_IDX((mwIndex) childData[1]) >= mxGetNumberOfElements(gCellTracks)) )
	{
		char errMsg[errBufSize];
		sprintf(errMsg, "Parent track %d has child ID larger than CellTracks", matParentID);
		gTrackErrors.insert(tErrorPair(C_IDX(trackID), errMsg));
		return false;
	}

	if ( (MATLAB_IDX((mwIndex) childData[0]) != C_IDX(trackID)) && (MATLAB_IDX((mwIndex) childData[1]) != C_IDX(trackID)) )
	{
		char errMsg[errBufSize];
		sprintf(errMsg, "Parent track %d does not have %d in children list", matParentID, (trackID+1));
		gTrackErrors.insert(tErrorPair(C_IDX(trackID), errMsg));
		return false;
	}

	if ( (MATLAB_IDX((mwIndex) childData[0]) != MATLAB_IDX(matSiblingID)) && (MATLAB_IDX((mwIndex) childData[1]) != MATLAB_IDX(matSiblingID)) )
	{
		char errMsg[errBufSize];
		sprintf(errMsg, "Parent track %d does not contain sibling track %d in children list", matParentID, matSiblingID);
		gTrackErrors.insert(tErrorPair(C_IDX(trackID), errMsg));
		return false;
	}

	return true;
}

bool checkChildParentReferences(mwIndex trackID)
{
	mxArray* childrenTracks = mxGetField(gCellTracks, C_IDX(trackID), "childrenTracks");

	if ( mxGetNumberOfElements(childrenTracks) == 0 )
		return true;

	double* childData = mxGetPr(childrenTracks);
	for ( int i=0; i < 2; ++i )
	{
		mwIndex matChildTrackID = (mwIndex) childData[i];
		mwIndex matOtherChild = (mwIndex) childData[1-i];

		if ( MATLAB_IDX(matChildTrackID) >= mxGetNumberOfElements(gCellTracks) )
		{
			gTrackErrors.insert(tErrorPair(C_IDX(trackID), "Track child ID is larger than size of CellTracks"));
			return false;
		}

		// Check that the child track isn't broken
		if ( gTrackErrors.count(MATLAB_IDX(matChildTrackID)) > 0 )
		{
			char errMsg[errBufSize];
			sprintf(errMsg, "Track links to broken child %d", matChildTrackID);
			gTrackErrors.insert(tErrorPair(C_IDX(trackID), errMsg));
			return false;
		}

		mxArray* childParent = mxGetField(gCellTracks, MATLAB_IDX(matChildTrackID), "parentTrack");
		mxArray* childSibling = mxGetField(gCellTracks, MATLAB_IDX(matChildTrackID), "siblingTrack");

		if ( mxGetNumberOfElements(childParent) == 0 )
		{
			char errMsg[errBufSize];
			sprintf(errMsg, "Child track %d has empty parent ID", matChildTrackID);
			gTrackErrors.insert(tErrorPair(C_IDX(trackID), errMsg));
			return false;
		}

		if ( mxGetNumberOfElements(childSibling) == 0 )
		{
			char errMsg[errBufSize];
			sprintf(errMsg, "Child track %d has empty sibling ID", matChildTrackID);
			gTrackErrors.insert(tErrorPair(C_IDX(trackID), errMsg));
			return false;
		}

		mwIndex matChildParentID = (mwIndex) mxGetScalar(childParent);
		mwIndex matChildSiblingID = (mwIndex) mxGetScalar(childSibling);

		if ( MATLAB_IDX(matChildParentID) >= mxGetNumberOfElements(gCellTracks) )
		{
			char errMsg[errBufSize];
			sprintf(errMsg, "Child track ID %d has parent ID larger than CellTracks", matChildTrackID);
			gTrackErrors.insert(tErrorPair(C_IDX(trackID), errMsg));
			return false;
		}

		if ( MATLAB_IDX(matChildSiblingID) >= mxGetNumberOfElements(gCellTracks) )
		{
			char errMsg[errBufSize];
			sprintf(errMsg, "Child track ID %d has sibling ID larger than CellTracks", matChildTrackID);
			gTrackErrors.insert(tErrorPair(C_IDX(trackID), errMsg));
			return false;
		}

		// Check child's parent is trackID
		if ( MATLAB_IDX(matChildParentID) != C_IDX(trackID) )
		{
			char errMsg[errBufSize];
			sprintf(errMsg, "Child track %d has track %d as parent", matChildTrackID, matChildParentID);
			gTrackErrors.insert(tErrorPair(C_IDX(trackID), errMsg));
			return false;
		}

		// Check that child's sibling is other child
		if ( MATLAB_IDX(matChildSiblingID) != MATLAB_IDX(matOtherChild) )
		{
			char errMsg[errBufSize];
			sprintf(errMsg, "Child track %d has track %d as sibling, should have %d", matChildTrackID, matChildSiblingID, matOtherChild);
			gTrackErrors.insert(tErrorPair(C_IDX(trackID), errMsg));
			return false;
		}
	}

	return true;
}

bool checkFamilyTrackReferences(mwIndex trackID)
{
	mwIndex matFamilyID = (mwIndex) mxGetScalar(mxGetField(gCellTracks, C_IDX(trackID), "familyID"));

	if ( MATLAB_IDX(matFamilyID) >= mxGetNumberOfElements(gCellFamilies) )
	{
		gTrackErrors.insert(tErrorPair(C_IDX(trackID), "Track's family ID is larger than CellFamilies"));
		return false;
	}

	if ( gFamilyErrors.count(MATLAB_IDX(matFamilyID)) )
	{
		//gTrackErrors.insert(tErrorPair(C_IDX(trackID), "Track links to broken family"));
		return false;
	}

	mxArray* familyTracks = mxGetField(gCellFamilies, MATLAB_IDX(matFamilyID), "tracks");

	double* trackData = mxGetPr(familyTracks);
	mwSize numTracks = mxGetNumberOfElements(familyTracks);
	for ( mwSize i=0; i < numTracks; ++i )
	{
		if ( MATLAB_IDX((mwIndex) trackData[i]) == C_IDX(trackID) )
			return true;
	}

	char errMsg[errBufSize];
	sprintf(errMsg, "Track is not in its family %d tracks list", matFamilyID);
	gTrackErrors.insert(tErrorPair(C_IDX(trackID), errMsg));
	return false;
}

int findTrackID(mwIndex matHullID)
{
	mwIndex matHullTime = (mwIndex) mxGetScalar(mxGetField(gCellHulls, MATLAB_IDX(matHullID), "time"));
	mxArray* frameHulls = mxGetCell(gHashHulls, MATLAB_IDX(matHullTime));

	if ( frameHulls == NULL )
		return -1;

	mwSize numHulls = mxGetNumberOfElements(frameHulls);
	for ( mwIndex i=0; i < numHulls; ++i )
	{
		if ( ((mwIndex) mxGetScalar(mxGetField(frameHulls, i, "hullID"))) == matHullID )
		{
			return ((mwIndex) mxGetScalar(mxGetField(frameHulls, i, "trackID")));
		}
	}

	return -1;
}

bool checkHullReferences(mwIndex trackID, std::vector<int>& hullRefCount)
{
	mxArray* trackHulls = mxGetField(gCellTracks, C_IDX(trackID), "hulls");

	mwIndex trackStartTime = (mwIndex) mxGetScalar(mxGetField(gCellTracks, C_IDX(trackID), "startTime"));
	mwIndex trackEndTime = (mwIndex) mxGetScalar(mxGetField(gCellTracks, C_IDX(trackID), "endTime"));

	mwSize numFrames = mxGetNumberOfElements(gHashHulls);

	mwSize numHulls = mxGetNumberOfElements(trackHulls);
	double* hullData = mxGetPr(trackHulls);
	for ( mwIndex i=0; i < numHulls; ++i )
	{
		mwIndex matHullID = (mwIndex) hullData[i];
		if ( matHullID == 0 )
			continue;

		if ( MATLAB_IDX(matHullID) >= mxGetNumberOfElements(gCellHulls) )
		{
			gTrackErrors.insert(tErrorPair(C_IDX(trackID), "Track hull list contains hull ID larger than CellHulls"));
			return false;
		}

		++hullRefCount[MATLAB_IDX(matHullID)];

		if ( gHullErrors.count(MATLAB_IDX(matHullID)) > 0 )
		{
			//gTrackErrors.insert(tErrorPair(C_IDX(trackID), "Track hull list references broken hulls"));
			continue;
		}

		bool bDeleted = (bool) mxGetScalar(mxGetField(gCellHulls, MATLAB_IDX(matHullID), "deleted"));

		if ( bDeleted )
		{
			char errMsg[errBufSize];
			sprintf(errMsg, "Track hull list references deleted hull %d", matHullID);
			gTrackErrors.insert(tErrorPair(C_IDX(trackID), errMsg));
			return false;
		}

		mwIndex hullTime = (mwIndex) mxGetScalar(mxGetField(gCellHulls, MATLAB_IDX(matHullID), "time"));
		mwIndex chkTime = trackStartTime + i;

		if ( MATLAB_IDX(hullTime) >= numFrames )
		{
			gTrackErrors.insert(tErrorPair(C_IDX(trackID), "Track hull list contains hull with time larger than number of frames"));
			return false;
		}

		int hullTrackID = findTrackID(matHullID);
		if ( hullTrackID == -1 )
		{
			char errMsg[errBufSize];
			sprintf(errMsg, "Hull %d on track is not in hashed hulls list", matHullID);
			gTrackErrors.insert(tErrorPair(C_IDX(trackID), errMsg));
			return false;
		}

		if ( MATLAB_IDX(hullTrackID) != C_IDX(trackID) )
		{
			char errMsg[errBufSize];
			sprintf(errMsg, "Hull %d on track has track ID %d", matHullID, hullTrackID);
			gTrackErrors.insert(tErrorPair(C_IDX(trackID), errMsg));
			return false;
		}

		if ( hullTime != chkTime )
		{
			char errMsg[errBufSize];
			sprintf(errMsg, "Hull %d on track has time %d, should be %d based on track startTime", matHullID, hullTime, chkTime);
			gTrackErrors.insert(tErrorPair(C_IDX(trackID), errMsg));
			return false;
		}

		if ( hullTime < trackStartTime || hullTime > trackEndTime )
		{
			char errMsg[errBufSize];
			sprintf(errMsg, "Hull %d on track has time %d, which is outside of track start/end time", matHullID, hullTime);
			gTrackErrors.insert(tErrorPair(C_IDX(trackID), errMsg));
			return false;
		}
	}

	return true;
}

bool verifyStructureElements()
{
	// Verify family,track,hull element structure first
	mwSize numFamilies = mxGetNumberOfElements(gCellFamilies);
	for ( int i=0; i < numFamilies; ++i )
	{
		if ( !checkFamilySizes(i) )
			continue;
	}

	mwSize numTracks = mxGetNumberOfElements(gCellTracks);
	for ( mwIndex i=0; i < numTracks; ++i )
	{
		if ( !checkTrackSizes(i) )
				continue;
	}

	std::vector<int> familyTrackRefCount;
	familyTrackRefCount.resize(mxGetNumberOfElements(gCellTracks));

	// Verify family->track references
	for ( mwIndex i=0; i < numFamilies; ++i )
	{
		// Ignore families for which we've already discovered errors
		if ( gFamilyErrors.count(i) > 0 )
			continue;

		// Don't check empty families
		mxArray* startTime = mxGetField(gCellFamilies, C_IDX(i), "startTime");
		if ( mxGetNumberOfElements(startTime) == 0 )
			continue;

		if ( !checkTrackFamilyReferences(i, familyTrackRefCount) )
			continue;
	}

	// Verify that all tracks referenced by CellFamilies are referenced no more than once
	for ( size_t i=0; i < familyTrackRefCount.size(); ++i )
	{
		if ( familyTrackRefCount[i] > 1 )
		{
			char errMsg[errBufSize];
			sprintf(errMsg, "Track referenced %d (>1) times by families", familyTrackRefCount[i]);
			gTrackErrors.insert(tErrorPair(C_IDX(i), errMsg));
		}
	}

	std::vector<int> trackHullRefCount;
	trackHullRefCount.resize(mxGetNumberOfElements(gCellHulls));

	// Verify track references
	for ( mwIndex i=0; i < numTracks; ++i )
	{
		// Ignore tracks for which we've already discovered errors
		if ( gTrackErrors.count(i) > 0 )
			continue;

		// Don't check empty tracks
		mxArray* startTime = mxGetField(gCellTracks, C_IDX(i), "startTime");
		if ( mxGetNumberOfElements(startTime) == 0 )
			continue;

		// Check parent->children->sibling relationship
		if ( !checkParentChildReferences(i) )
			continue;

		// Check children->parent->sibling relationship
		if ( !checkChildParentReferences(i) )
			continue;

		// Check that track is in its family's track list, only necessary for tracks not referenced in CellFamilies
		// Makes sure no non-empty orphan tracks exist
		//if ( familyTrackRefCount[i] == 0 )
		{
			if ( !checkFamilyTrackReferences(i) )
				continue;
		}

		if ( !checkHullReferences(i, trackHullRefCount) )
			continue;
	}


	// Verify that all hulls referenced by CellTracks are referenced no more than once
	for ( size_t i=0; i < trackHullRefCount.size(); ++i )
	{
		if ( trackHullRefCount[i] > 1 )
		{
			char errMsg[errBufSize];
			sprintf(errMsg, "Hull referenced %d (>1) times by tracks", trackHullRefCount[i]);
			gHullErrors.insert(tErrorPair(C_IDX(i), errMsg));
		}
	}

	// Check for orphaned hulls or deleted hulls which are still referenced
	mwSize numFrames = mxGetNumberOfElements(gHashHulls);
	mwSize numHulls = mxGetNumberOfElements(gCellHulls);
	for ( mwIndex i=0; i < numHulls; ++i )
	{
		bool bHullDeleted = (bool) mxGetScalar(mxGetField(gCellHulls, C_IDX(i), "deleted"));
		if ( bHullDeleted )
			continue;

		int trackID = findTrackID(i+1);
		mwIndex matHullTime = mxGetScalar(mxGetField(gCellHulls, C_IDX(i), "time"));
		if ( (matHullTime == 0) || (MATLAB_IDX(matHullTime) >= numFrames) )
		{
			gHullErrors.insert(tErrorPair(C_IDX(i), "Hull time is invalid"));
			continue;
		}

		if ( trackHullRefCount[i] == 1 )
			continue;

		if ( trackID < 0 )
		{
			gHullErrors.insert(tErrorPair(C_IDX(i), "Hull has no CellTracks ref or HashedCells ref (not deleted)"));
			continue;
		}

		char errMsg[errBufSize];
		sprintf(errMsg, "Hull has no CellTracks references HashedCells.trackID = %d (not deleted)", trackID);
		gHullErrors.insert(tErrorPair(C_IDX(i), errMsg));
		continue;
	}

	// Reuse these for HashedCells ref count
	for ( size_t i=0; i < familyTrackRefCount.size(); ++i )
		familyTrackRefCount[i] = 0;

	for ( size_t i=0; i < trackHullRefCount.size(); ++i )
		trackHullRefCount[i] = 0;

	for ( mwIndex i=0; i < numFrames; ++i )
	{
		mxArray* frameHulls = mxGetCell(gHashHulls, C_IDX(i));
		if ( frameHulls == NULL )
		{
			gHashErrors.insert(tErrorPair(C_IDX(i), "HashCells contains empty cell (non-structured)"));
			continue;
		}

		mwSize numEntries = mxGetNumberOfElements(frameHulls);

		for ( mwIndex j=0; j < numEntries; ++j )
		{
			mwIndex matHashTrack = (mwIndex) mxGetScalar(mxGetField(frameHulls, C_IDX(j), "trackID"));
			mwIndex matHashHull = (mwIndex) mxGetScalar(mxGetField(frameHulls, C_IDX(j), "hullID"));

			if ( (matHashHull == 0) || (MATLAB_IDX(matHashHull) >= numHulls) )
			{
				char errMsg[errBufSize];
				sprintf(errMsg, "HashCells contains invalid hull entry at %d", (j+1));
				gHullErrors.insert(tErrorPair(MATLAB_IDX(matHashHull), errMsg));
				continue;
			}

			if ( (matHashTrack == 0) || (MATLAB_IDX(matHashTrack) >= numTracks) )
			{
				char errMsg[errBufSize];
				sprintf(errMsg, "HashCells contains invalid track entry at %d", j+1);
				gHullErrors.insert(tErrorPair(MATLAB_IDX(matHashHull), errMsg));
				continue;
			}

			++familyTrackRefCount[MATLAB_IDX(matHashTrack)];
			++trackHullRefCount[MATLAB_IDX(matHashHull)];

			mxArray* trackStartTime = mxGetField(gCellTracks, MATLAB_IDX(matHashTrack), "startTime");
			if ( mxGetNumberOfElements(trackStartTime) == 0 )
			{
				char errMsg[errBufSize];
				sprintf(errMsg, "Hull references empty track %d", matHashTrack);
				gHullErrors.insert(tErrorPair(MATLAB_IDX(matHashHull), errMsg));
			}

			bool bHullDeleted = (bool) mxGetScalar(mxGetField(gCellHulls, MATLAB_IDX(matHashHull), "deleted"));
			if ( bHullDeleted )
			{
				char errMsg[errBufSize];
				sprintf(errMsg, "Hash references deleted hull %d", matHashHull);
				gHashErrors.insert(tErrorPair(C_IDX(i), errMsg));
			}
		}
	}

	return true;
}


// Main entry point
void mexFunction(int nlhs, mxArray* plhs[], int nrhs, const mxArray* prhs[])
{
	if ( nrhs != 0 )
		mexErrMsgTxt("Input arguments unsupported");

	if ( nlhs != 1 )
		mexErrMsgTxt("Must have one output argument");

	//
	gCellHulls = mexGetVariablePtr("global", "CellHulls");
	gCellTracks = mexGetVariablePtr("global", "CellTracks");
	gCellFamilies = mexGetVariablePtr("global", "CellFamilies");
	gHashHulls = mexGetVariablePtr("global", "HashedCells");
	gCellPhenotypes = mexGetVariablePtr("global", "CellPhenotypes");

	gFamilyErrors.clear();
	gTrackErrors.clear();
	gHullErrors.clear();
	gHashErrors.clear();

	verifyStructureElements();

	size_t numErrors = gFamilyErrors.size() + gTrackErrors.size() + gHullErrors.size() + gHashErrors.size();

	const char* errFields[] = {"type", "index", "message"};
	const int numFields = ARRAY_SIZE(errFields);

	plhs[0] = mxCreateStructMatrix(numErrors, 1, numFields, errFields);

	size_t idx = 0;
	tErrorList::iterator errIter = gTrackErrors.begin();
	for ( ; errIter != gTrackErrors.end(); ++errIter, ++idx )
	{
		//mexPrintf("ERROR: Track %d: %s\n", (errIter->first + 1), errIter->second.c_str());
		mxArray* newType = mxCreateString("CellTracks");
		mxArray* newIndex = mxCreateDoubleScalar((double) (errIter->first + 1));
		mxArray* newMsg = mxCreateString(errIter->second.c_str());

		mxSetField(plhs[0], idx, "type", newType);
		mxSetField(plhs[0], idx, "index", newIndex);
		mxSetField(plhs[0], idx, "message", newMsg);
	}

	errIter = gFamilyErrors.begin();
	for ( ; errIter != gFamilyErrors.end(); ++errIter, ++idx )
	{
		//mexPrintf("ERROR: Family %d: %s\n", (errIter->first + 1), errIter->second.c_str());
		mxArray* newType = mxCreateString("CellFamilies");
		mxArray* newIndex = mxCreateDoubleScalar((double) (errIter->first + 1));
		mxArray* newMsg = mxCreateString(errIter->second.c_str());

		mxSetField(plhs[0], idx, "type", newType);
		mxSetField(plhs[0], idx, "index", newIndex);
		mxSetField(plhs[0], idx, "message", newMsg);
	}

	errIter = gHullErrors.begin();
	for ( ; errIter != gHullErrors.end(); ++errIter, ++idx )
	{
		//mexPrintf("ERROR: Hull %d: %s\n", (errIter->first + 1), errIter->second.c_str());
		mxArray* newType = mxCreateString("CellHulls");
		mxArray* newIndex = mxCreateDoubleScalar((double) (errIter->first + 1));
		mxArray* newMsg = mxCreateString(errIter->second.c_str());

		mxSetField(plhs[0], idx, "type", newType);
		mxSetField(plhs[0], idx, "index", newIndex);
		mxSetField(plhs[0], idx, "message", newMsg);
	}

	errIter = gHashErrors.begin();
	for ( ; errIter != gHashErrors.end(); ++errIter, ++idx )
	{
		//mexPrintf("ERROR: Hash-time %d: %s\n", (errIter->first + 1), errIter->second.c_str());
		mxArray* newType = mxCreateString("HashedCells");
		mxArray* newIndex = mxCreateDoubleScalar((double) (errIter->first + 1));
		mxArray* newMsg = mxCreateString(errIter->second.c_str());

		mxSetField(plhs[0], idx, "type", newType);
		mxSetField(plhs[0], idx, "index", newIndex);
		mxSetField(plhs[0], idx, "message", newMsg);
	}

	return;
}
