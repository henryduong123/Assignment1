#include <stdlib.h>
#include <string>

#include "Segmentation.h"
#include "Helpers.h"

int main(int argc, char * argv[])
{
	if(argc<5)
	{
		printf_s("Usage message here");//TODO this line
		return 0;
	}

	SYSTEM_INFO sysinfo;
	GetSystemInfo( &sysinfo );

	int numCPU = sysinfo.dwNumberOfProcessors;

	segData* pArguments = new segData[numCPU];
	DWORD*   dwThreadIdArray = new DWORD[numCPU];
	HANDLE*  hThreadArray = new HANDLE[numCPU]; 

	std::string imagePath = pathCreate(argv[1]);

	std::string searchPath(imagePath);
	searchPath += "\\*.*";

	WIN32_FIND_DATAA fileNames;
	HANDLE handle = FindFirstFileA(searchPath.c_str(),&fileNames);

	pathCreate(".\\segmentationData\\");
	int nextEmptyThread = 0;
	bool filling = TRUE;

	srand(time(NULL));

	if( handle!=INVALID_HANDLE_VALUE ) 
	{
		do
		{
			std::string curfile(imagePath);
			curfile += "\\";
			curfile += fileNames.cFileName;

			std::string outputfile(".\\segmentationData\\");
			outputfile += fileNames.cFileName;
			outputfile += "_seg.txt";

			if (isTiffFile(curfile))
			{
				pArguments[nextEmptyThread].imageFile = curfile;
				pArguments[nextEmptyThread].outFile = outputfile;
				pArguments[nextEmptyThread].imageAlpha = atof(argv[2]);
				pArguments[nextEmptyThread].minSize = atoi(argv[3]);
				pArguments[nextEmptyThread].eccentricity = atof(argv[4]);

				hThreadArray[nextEmptyThread] = CreateThread(
					NULL,
					0,
					segmentation,
					(LPVOID)(&pArguments[nextEmptyThread]),
					FALSE,
					&dwThreadIdArray[nextEmptyThread]);

				if( hThreadArray[nextEmptyThread] == NULL )
				{
					printf("CreateThread error: %d\n", GetLastError());
					return 1;
				}

				++nextEmptyThread;
				if (nextEmptyThread==numCPU)
					filling = false;

				if(!filling)
				{
					DWORD doneThread = WaitForMultipleObjects(
						numCPU,
						hThreadArray,
						FALSE,
						INFINITE);

					DWORD ind = doneThread - WAIT_OBJECT_0;
					nextEmptyThread = ind;
					if (nextEmptyThread>=numCPU)
					{
						char* message;
						FormatMessageA(
							FORMAT_MESSAGE_ALLOCATE_BUFFER|FORMAT_MESSAGE_FROM_SYSTEM,
							NULL,
							GetLastError(),
							0,
							(LPSTR)&message,
							10,
							NULL);
						printf_s(message);
					}
				}
			}

		} while(FindNextFileA(handle,&fileNames));
	}

	if (filling)
	{
		WaitForMultipleObjects(
			nextEmptyThread,
			hThreadArray,
			TRUE,
			INFINITE);
	}else
	{
		WaitForMultipleObjects(
			numCPU,
			hThreadArray,
			TRUE,
			INFINITE);
	}

	FindClose(handle);
	delete[] pArguments;
	delete[] dwThreadIdArray;
	delete[] hThreadArray;

	return 0;
}