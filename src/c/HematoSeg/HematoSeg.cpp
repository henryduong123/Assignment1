#include <stdlib.h>
#include <string>

#include "Segmentation.h"
#include "Helpers.h"

int main(int argc, char * argv[])
{
	if(argc<3)
	{
		printf_s("Usage message here");//TODO this line
		return 0;
	}

	std::string imagePath = pathCreate(argv[1]);

	std::string searchPath(imagePath);
	searchPath += "\\*.*";

	WIN32_FIND_DATAA fileNames;
	HANDLE handle = FindFirstFileA(searchPath.c_str(),&fileNames);

	pathCreate(".\\segmentationData\\");

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
				segmentation(curfile,outputfile,atoi(argv[2]),300);
			}

		} while(FindNextFileA(handle,&fileNames));
	}

	FindClose(handle);

	return 0;
}