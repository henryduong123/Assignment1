/***********************************************************************
*     Copyright 2011-2016 Andrew Cohen
*
*     This file is part of LEVer - the tool for stem cell lineaging. See
*     http://n2t.net/ark:/87918/d9rp4t for details
* 
*     LEVer is free software: you can redistribute it and/or modify
*     it under the terms of the GNU General Public License as published by
*     the Free Software Foundation, either version 3 of the License, or
*     (at your option) any later version.
* 
*     LEVer is distributed in the hope that it will be useful,
*     but WITHOUT ANY WARRANTY; without even the implied warranty of
*     MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
*     GNU General Public License for more details.
* 
*     You should have received a copy of the GNU General Public License
*     along with LEVer in file "gnu gpl v3.txt".  If not, see 
*     <http://www.gnu.org/licenses/>.
*
***********************************************************************/
#include "mexHashData.h"

#include <string.h>

#include <string>
#include <vector>
#include <map>
#include <set>

#define ARRAY_SIZE(x) (sizeof(x) / sizeof((x)[0]))

void hashData(SHA1Context* pShaContext, const mxArray* pData);

// Globals

std::set<std::string> gIgnoreFields;

template <class T>
void hashElementData(SHA1Context* pShaContext, const T* elemData, const size_t numElems)
{
	SHA1Input(pShaContext, (const unsigned char*)elemData, numElems*sizeof(T));
}

void hashElementData(SHA1Context* pShaContext, const void* elemData, const size_t numElems, const size_t elemSize)
{
	SHA1Input(pShaContext, (const unsigned char*)elemData, numElems*elemSize);
}

void hashDimSize(SHA1Context* pShaContext, const mxArray* pData)
{
	const int nDims = mxGetNumberOfDimensions(pData);
	const mwSize* dims = mxGetDimensions(pData);

	hashElementData<mwSize>(pShaContext, dims, nDims);
}

void hashLogicalArray(SHA1Context* pShaContext, const mxArray* pData)
{
}

void hashSparseLogicalArray(SHA1Context* pShaContext, const mxArray* pData)
{
}

void hashNumericArray(SHA1Context* pShaContext, const mxArray* pData)
{
	hashDimSize(pShaContext, pData);

	mwSize numElem = mxGetNumberOfElements(pData);
	if ( numElem == 0 )
		return;

	mwSize elemSize = mxGetElementSize(pData);

	hashElementData(pShaContext, mxGetData(pData), numElem, elemSize);

	if ( mxIsComplex(pData) )
		hashElementData(pShaContext, mxGetImagData(pData), numElem, elemSize);
}

void hashStringArray(SHA1Context* pShaContext, const mxArray* pData)
{
	hashDimSize(pShaContext, pData);

	mwSize numElem = mxGetNumberOfElements(pData);
	if ( numElem == 0 )
		return;

	mxChar* pCharData = (mxChar*) mxGetData(pData);

	hashElementData<mxChar>(pShaContext, pCharData, numElem);
}

void hashSparseArray(SHA1Context* pShaContext, const mxArray* pData)
{
	hashDimSize(pShaContext, pData);

	mwSize numCols = mxGetN(pData);

	if ( numCols == 0 )
		return;

	mwIndex* pJc = mxGetJc(pData);
	mwIndex* pIr = mxGetIr(pData);
	double* pElemData = mxGetPr(pData);

	mwSize numNonzero = pJc[numCols-1];

	if ( numNonzero == 0 )
		return;

	hashElementData<mwIndex>(pShaContext, pJc, numCols);
	hashElementData<mwIndex>(pShaContext, pIr, numNonzero);
	hashElementData<double>(pShaContext, pElemData, numNonzero);

	if ( mxIsComplex(pData) )
	{
		double* pComplexData = mxGetPi(pData);
		hashElementData<double>(pShaContext, pComplexData, numNonzero);
	}
}

void hashCellArray(SHA1Context* pShaContext, const mxArray* pData)
{
	hashDimSize(pShaContext, pData);

	mwSize numElem = mxGetNumberOfElements(pData);

	for ( int i=0; i < numElem; ++i )
	{
		mxArray* cellElem = mxGetCell(pData, i);
		hashData(pShaContext, cellElem);
	}
}

void hashFieldNames(SHA1Context* pShaContext, const mxArray* pData, std::vector<bool>* bIgnoreFields)
{
	//std::set<std::string> sortFields;

	int numFields = mxGetNumberOfFields(pData);
	bIgnoreFields->resize(numFields);
	for ( int i=0; i < numFields; ++i )
	{
		//std::string fieldName(mxGetFieldNameByNumber(pData, i));
		//sortFields.insert(fieldName);
		const char* fieldName = mxGetFieldNameByNumber(pData, i);
		SHA1Input(pShaContext, (const unsigned char*)fieldName, strlen(fieldName));

		if ( gIgnoreFields.count(fieldName) > 0 )
			bIgnoreFields->at(i) = true;
	}

	//std::set<std::string>::iterator setIter = sortFields.begin();
	//for ( ; setIter != sortFields.end(); ++setIter )
	//	SHA1Input(pShaContext, (unsigned char*)setIter->c_str(), setIter->length());
}

void hashStructArray(SHA1Context* pShaContext, const mxArray* pData)
{
	std::vector<bool> bIgnoreFields;

	hashDimSize(pShaContext, pData);
	hashFieldNames(pShaContext, pData, &bIgnoreFields);

	int numElems = mxGetNumberOfElements(pData);
	if ( numElems == 0 )
		return;

	int numFields = mxGetNumberOfFields(pData);

	for ( int i=0; i < numElems; ++i )
	{
		for ( int j=0; j < numFields; ++j )
		{
			if ( bIgnoreFields[j] )
				continue;

			hashData(pShaContext, mxGetFieldByNumber(pData, i, j));
		}
	}
}

void hashData(SHA1Context* pShaContext, const mxArray* pData)
{
	// If the data pointer is null (e.g. empty cells/structs)
	// then just hash the NULL pointer
	if ( pData == NULL )
	{
		hashElementData<const mxArray*>(pShaContext, &pData, 1);

		return;
	}

	mxClassID classID = mxGetClassID(pData);

	switch (classID)
	{
		case mxCHAR_CLASS:
		{
			hashStringArray(pShaContext, pData);
			break;
		}

		case mxCELL_CLASS:
		{
			hashCellArray(pShaContext, pData);
			break;
		}

		case mxSTRUCT_CLASS:
		{
			hashStructArray(pShaContext, pData);
			break;
		}

		case mxFUNCTION_CLASS:
		{
			mxArray* pFunctionString;
			mxArray* pInput = mxDuplicateArray(pData);
			mexCallMATLAB(1, &pFunctionString, 1, &pInput, "func2str");
			hashStringArray(pShaContext, pFunctionString);
			break;
		}

		case mxLOGICAL_CLASS:
		{
			if ( mxIsSparse(pData) )
				hashSparseLogicalArray(pShaContext, pData);
			else
				hashLogicalArray(pShaContext, pData);

			break;
		}

		case mxDOUBLE_CLASS:
		case mxSINGLE_CLASS:
		case mxINT8_CLASS:
		case mxUINT8_CLASS:
		case mxINT16_CLASS:
		case mxUINT16_CLASS:
		case mxINT32_CLASS:
		case mxUINT32_CLASS:
		case mxINT64_CLASS:
		case mxUINT64_CLASS:
		{
			if ( mxIsSparse(pData) )
				hashSparseArray(pShaContext, pData);
			else
				hashNumericArray(pShaContext, pData);

			break;
		}

		case mxVOID_CLASS:
		case mxUNKNOWN_CLASS:
		default:
			mexErrMsgTxt("Cannot hash data of unknown or void class");
	}
}

bool parseOpts(int nrhs, const mxArray* prhs[], std::set<std::string>* ignoreFields)
{
	for (int i=1; i < nrhs; ++i)
	{
		if ( !mxIsChar(prhs[i]) )
			mexErrMsgTxt("Key must be a string");

		char* key = mxArrayToString(prhs[i]);
		if ( strcmpi(key, "-ignoreField") != 0 )
			mexErrMsgTxt("Unsupported option");

		++i;
		if ( !mxIsChar(prhs[i]) )
			mexErrMsgTxt("Ignore field must be string");

		char* value = mxArrayToString(prhs[i]);
		ignoreFields->insert(value);
	}

	return true;
}

// Main entry point
void mexFunction(int nlhs, mxArray* plhs[], int nrhs, const mxArray* prhs[])
{
	if ( (nrhs % 2) != 1)
		mexErrMsgTxt("Expect one input array or structure, additional options must come in key-value pairs");

	if ( nlhs != 1 )
		mexErrMsgTxt("Must have one output argument");

	gIgnoreFields.clear();
	parseOpts(nrhs, prhs, &gIgnoreFields);

	SHA1Context shaContext;
	SHA1Reset(&shaContext);

	hashData(&shaContext, prhs[0]);

	if ( !SHA1Result(&shaContext) )
		mexErrMsgTxt("Could not compute SHA-1 for specified data.");

	char hashWord[10];
	char hashString[200];

	hashString[0] = '\0';
	for ( int i=0; i < 5; ++i )
	{
		sprintf(hashWord, "%08X", shaContext.Message_Digest[i]);
		strcat(hashString, hashWord);
	}

	plhs[0] = mxCreateString(hashString);

	return;
}
