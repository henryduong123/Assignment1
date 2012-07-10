#include <stdlib.h>
#include <string>

#include "Segmentation.h"
#include "Helpers.h"
#include "Threader.h"

int main(int argc, char * argv[])
{
	if(argc<=5)
	{
		printf_s("Usage message here");//TODO this line
		return 0;
	}

	double processorUsage = 1.0;
	if (argc==6)
	{
		processorUsage = atof(argv[5]);
	}

	Threader threader(processorUsage);

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
		
		std::vector<segData> pArguments;

		do
		{
			std::string curfile(imagePath);
			curfile += "\\";
			curfile += fileNames.cFileName;

			std::string outputfile(".\\segmentationData\\");
			outputfile += fileNames.cFileName;
			outputfile += "_seg.txt";

			if (isTiffFile(curfile) && !fileExists(outputfile.c_str()))
			{
				segData curImage;

				curImage.imageFile = curfile;
				curImage.outFile = outputfile;
				curImage.imageAlpha = atof(argv[2]);
				curImage.minSize = atoi(argv[3]);
				curImage.eccentricity = atof(argv[4]);
				pArguments.push_back(curImage);
			}

		} while(FindNextFileA(handle,&fileNames));

		for (int i=0; i<pArguments.size(); ++i)
		{
			threader.add(segmentation,&pArguments[i]);
		}

		threader.run();
	}

	return 0;
}