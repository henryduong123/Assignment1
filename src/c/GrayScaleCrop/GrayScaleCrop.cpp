#include <string>
#include <iostream>
#include <fstream>

#include "Threader.h"
#include "itkImageFileReader.h"
#include "itkImageFileWriter.h"
#include "itkTIFFImageIO.h"
#include "itkImage.h"
#include "itkImageRegionConstIterator.h"
#include "itkImageRegionIterator.h"
#include "itkScalarImageToHistogramGenerator.h"
#include "itkOtsuThresholdCalculator.h"
#include "itkBinaryThresholdImageFilter.h"
#include "itkConnectedComponentImageFilter.h"
#include "itkLabelGeometryImageFilter.h"

#define DIMENSIONS (2)

typedef unsigned char CharPixelType;
typedef unsigned short ShortPixelType;
typedef itk::Image<CharPixelType, DIMENSIONS> CharImageType;
typedef itk::Image<ShortPixelType, DIMENSIONS> ShortImageType;
typedef itk::ImageFileReader<CharImageType> CharImageFileReaderType;
typedef itk::ImageFileWriter<CharImageType> CharImageFileWriterType;
typedef itk::ImageRegionConstIterator<CharImageType> ConstIteratorType;
typedef itk::ImageRegionIterator<CharImageType> IteratorType;
typedef itk::Statistics::ScalarImageToHistogramGenerator<CharImageType> ScalarImageToHistogramGeneratorType;
typedef itk::OtsuThresholdCalculator<ScalarImageToHistogramGeneratorType::HistogramType> OtsuThresholdCalculatorType;
typedef itk::BinaryThresholdImageFilter<CharImageType, CharImageType> ThresholdFilterType;
typedef itk::ConnectedComponentImageFilter<CharImageType,CharImageType> ConnectedComponentFilterType;
typedef itk::LabelGeometryImageFilter<CharImageType,CharImageType> LabelGeometryImageFilterType;

struct cropData{
	std::string filePath;
	std::string imageName;
	CharImageType::RegionType regionToKeep;
	std::string destination;
};

std::string pathCreate(std::string path)
{
	size_t directoryEnd=path.find_first_of("/\\");
	std::string dir = "";

	while (directoryEnd<path.length()+1)
	{
		dir = path.substr(0,directoryEnd);
		if (dir.find_last_of(".")!=std::string::npos  && directoryEnd>=path.length())
			break;

		if (!CreateDirectoryA(dir.c_str(),NULL))
		{
			if (ERROR_PATH_NOT_FOUND==GetLastError())
				return false;
		}

		if (path.length()<=directoryEnd)
			break;

		std::string sub = path.substr(directoryEnd+1,std::string::npos);

		size_t temp = sub.find_first_of("/\\");
		if (temp==std::string::npos && path.length()>directoryEnd)
			directoryEnd = path.length();
		else
			directoryEnd += temp+1;
	}
	dir = path.substr(0,path.find_last_of("/\\"));
	return dir;
}

bool fileExists(const char* filename){
	std::ifstream ifile(filename);
	bool rtn = ifile.good();
	ifile.close();
	return rtn;
}

bool isTiffFile(std::string filePath)
{
	if(!fileExists(filePath.c_str())) return false;

	size_t pos = filePath.find_last_of(".");

	if (pos==std::string::npos) return false;

	std::string	ext = filePath.substr(pos+1,std::string::npos);
	if (_strcmpi(ext.c_str(),"tif")!=0 && _strcmpi(ext.c_str(),"tiff")!=0) return false;

	return true;
}

DWORD WINAPI crop(LPVOID paramaters)
{
	cropData* param = (cropData*)paramaters;
	CharImageFileReaderType::Pointer	reader =		CharImageFileReaderType::New();
	CharImageFileWriterType::Pointer	writer =	CharImageFileWriterType::New();
	itk::TIFFImageIO::Pointer			imageIO =	itk::TIFFImageIO::New();

	CharImageType::Pointer		newImage = CharImageType::New();
	CharImageType::IndexType	newStart;
	CharImageType::RegionType	newRegion;

	newStart.Fill(0);
	newRegion.SetIndex(newStart);
	newRegion.SetSize(param->regionToKeep.GetSize());

	newImage->SetRegions(newRegion);
	newImage->Allocate();

	reader->SetImageIO(imageIO);
	reader->SetFileName(param->filePath + param->imageName);
	reader->Update();

	ConstIteratorType inputIt(reader->GetOutput(), param->regionToKeep);
	IteratorType outputIt(newImage, newRegion);
	for (inputIt.GoToBegin(), outputIt.GoToBegin(); !inputIt.IsAtEnd(); ++inputIt, ++outputIt){
		outputIt.Set(inputIt.Get());
	}

	writer->SetImageIO(imageIO);
	writer->SetFileName(param->destination + param->imageName);
	writer->SetInput(newImage);
	writer->Update();

	printf("Wrote out image: %s\n",(param->destination + param->imageName).c_str());

	return 0;
}

//#pragma optimize("",off)
CharImageType::RegionType findRegion( std::string curfile ) 
{
	CharImageFileReaderType::Pointer			reader =			CharImageFileReaderType::New();
	//CharImageFileWriterType::Pointer			writer =			CharImageFileWriterType::New();
	itk::TIFFImageIO::Pointer					imageIO =			itk::TIFFImageIO::New();
	ScalarImageToHistogramGeneratorType::Pointer histogramGenerator = ScalarImageToHistogramGeneratorType::New();
	OtsuThresholdCalculatorType::Pointer		thresholdCalculator = OtsuThresholdCalculatorType::New();
	ThresholdFilterType::Pointer				thresholdFilter =	ThresholdFilterType::New();
	ConnectedComponentFilterType::Pointer		labeler =			ConnectedComponentFilterType::New();
	LabelGeometryImageFilterType::Pointer		labelGeometryImageFilter = LabelGeometryImageFilterType::New();
	CharImageType::RegionType region;
	CharImageType::IndexType index;
	CharImageType::SizeType	size;

	index.Fill(0);
	size.Fill(0);

	reader->SetImageIO(imageIO);
	reader->SetFileName(curfile);
	reader->Update();

	histogramGenerator->SetNumberOfBins(256);
	histogramGenerator->SetInput(reader->GetOutput());
	histogramGenerator->Compute();

	thresholdCalculator->SetInput(histogramGenerator->GetOutput());
	thresholdCalculator->Update();

	itk::SimpleDataObjectDecorator<double>* thresh = thresholdCalculator->GetOutput();
	float threshold = thresh->Get();

	thresholdFilter->SetLowerThreshold(threshold);
	thresholdFilter->SetOutsideValue(0);
	thresholdFilter->SetInsideValue(-1);
	thresholdFilter->SetUpperThreshold(-1);
	thresholdFilter->SetInput(reader->GetOutput());

	//writer->SetFileName("thres.tif");
	//writer->SetImageIO(imageIO);
	//writer->SetInput(thresholdFilter->GetOutput());
	//writer->Update();

	labeler->SetInput(thresholdFilter->GetOutput());
	labelGeometryImageFilter->SetInput(labeler->GetOutput());
	try
	{
		labelGeometryImageFilter->Update();
	}
	catch (...)
	{
		printf("Unable to find region of %s!\n",curfile.c_str());
		return region;
	}

	std::vector<CharPixelType> labels = labelGeometryImageFilter->GetLabels();

	region = labelGeometryImageFilter->GetRegion(1);

	index = region.GetIndex();
	size = region.GetSize();

	index[0] += 5;
	index[1] += 5;
	size[0] -= 10;
	size[1] -= 10;

	region.SetIndex(index);
	region.SetSize(size);

	return region;
}

int main(int argc, char * argv[])
{
	if (argc<3)
	{
		printf("Usage %s FilePath\\* DestinationPath\\. [indexX indexY sizeX sizeY]",argv[0]);
		int dummy;
		std::cin >> dummy;
		return 1;
	}

	Threader threader(0.8);

	bool regionSet = false;
	CharImageType::RegionType	region;

	if (argc==7)
	{
		CharImageType::IndexType index;
		CharImageType::SizeType	size;
		index[0] = atoi(argv[3]);
		index[1] = atoi(argv[4]);
		size[0] = atoi(argv[5]);
		size[1] = atoi(argv[6]);

		region.SetIndex(index);
		region.SetSize(size);
		regionSet = true;
	}

	std::string imageDir = pathCreate(argv[1]);
	std::string search = imageDir.c_str();
	search += "\\*.*";

	std::string croppedDir = pathCreate(argv[2]);
	
	WIN32_FIND_DATAA fileNames;
	HANDLE handle = FindFirstFileA(search.c_str(),&fileNames);

	std::vector<cropData> pArguments;

	if( handle!=INVALID_HANDLE_VALUE ) 
	{
		do
		{
			std::string curfile(imageDir);
			curfile += "\\";
			curfile += fileNames.cFileName;

			if (isTiffFile(curfile))
			{
				if (!regionSet){
					region = findRegion(curfile);
					if(region.GetSize()[0]==0 || region.GetSize()[1]==0)
						return 1;

					// print out what is to be cropped for later use
					std::string cropFile(imageDir);
					cropFile += "\\cropDimentions.txt";
					FILE* cropDim;
					fopen_s(&cropDim,cropFile.c_str(),"w");
					fprintf_s(cropDim,"Start Index: (%d,%d)\nSize: %d x %d\n",
						region.GetIndex()[0],region.GetIndex()[1],
						region.GetSize()[0],region.GetSize()[1]);
					fclose(cropDim);

					regionSet = true;
				}

				cropData curData;
				curData.filePath = (imageDir+"\\");
				curData.imageName = fileNames.cFileName;
				curData.regionToKeep = region;
				curData.destination = (croppedDir+"\\");

				pArguments.push_back(curData);
			}

		} while(FindNextFileA(handle,&fileNames));
	}

	FindClose(handle);

	for (int i=0; i<pArguments.size(); ++i)
	{
		threader.add(crop, &pArguments[i]);
	}

	threader.run();

	return 0;
}