#include "Segmentation.h"
#include "itkTIFFImageIO.h"

#include "GapStatistic.h"

DWORD WINAPI segmentation(LPVOID lpParam)
{
	segData* paramaters = (segData*)lpParam;

	CharImageFileReaderType::Pointer		charReader =		CharImageFileReaderType::New();
	CharImageFileWriterType::Pointer		charWriter =		CharImageFileWriterType::New();

	itk::TIFFImageIO::Pointer				imageIO =			itk::TIFFImageIO::New();

	ScalarImageToHistogramGeneratorType::Pointer histogramGenerator = ScalarImageToHistogramGeneratorType::New();
	OtsuThresholdCalculatorType::Pointer	thresholdCalculator = OtsuThresholdCalculatorType::New();

	ThresholdFilterType::Pointer			thresholdFilter =	ThresholdFilterType::New();
	
	ErodeFilterType::Pointer				binaryErode =		ErodeFilterType::New();
	DilateFilterType::Pointer				binaryDilate =		DilateFilterType::New();
	ErodeFilterType::Pointer				binaryErode2 =		ErodeFilterType::New();
	DilateFilterType::Pointer				binaryDilate2 =		DilateFilterType::New();
	BinaryFillholeImageFilterType::Pointer  binaryHoleFiller =  BinaryFillholeImageFilterType::New();
	ConnectedComponentFilterType::Pointer	labeler =			ConnectedComponentFilterType::New();
	RelabelComponentFilterType::Pointer		relabeler =			RelabelComponentFilterType::New();
	LabelGeometryImageFilterType::Pointer	labelGeometryImageFilter = LabelGeometryImageFilterType::New();
	
	StructuringElementType		structuringElement;

	charReader->SetImageIO(imageIO);
	charReader->SetFileName(paramaters->imageFile);
	charReader->Update();

	histogramGenerator->SetNumberOfBins(256);
	histogramGenerator->SetInput(charReader->GetOutput());
	histogramGenerator->Compute();

	thresholdCalculator->SetInput(histogramGenerator->GetOutput());
	thresholdCalculator->Update();

	itk::SimpleDataObjectDecorator<double>* thresh = thresholdCalculator->GetOutput();
	float threshold = thresh->Get();

	threshold *= paramaters->imageAlpha;

	thresholdFilter->SetLowerThreshold(threshold);
	thresholdFilter->SetOutsideValue(0);
	thresholdFilter->SetInsideValue(-1);
	thresholdFilter->SetUpperThreshold(255);
	thresholdFilter->SetInput(charReader->GetOutput());

	structuringElement.SetRadius(4);
	structuringElement.CreateStructuringElement();

	binaryErode->SetKernel(structuringElement);
	binaryErode->SetInput(thresholdFilter->GetOutput());

	binaryDilate->SetKernel(structuringElement);
	binaryDilate->SetInput(binaryErode->GetOutput());

	binaryDilate2->SetKernel(structuringElement);
	binaryDilate2->SetInput(binaryDilate->GetOutput());

	binaryErode2->SetKernel(structuringElement);
	binaryErode2->SetInput(binaryDilate2->GetOutput());

	binaryHoleFiller->SetInput(binaryErode2->GetOutput());
	binaryHoleFiller->SetFullyConnected(false);

	//charWriter->SetFileName("D:\\Desktop\\holefiller.tiff");
	//charWriter->SetImageIO(imageIO);
	//charWriter->SetInput(binaryHoleFiller->GetOutput());
	//charWriter->Update();

	//labeler->SetInput(binaryDilate2->GetOutput());
	labeler->SetInput(binaryHoleFiller->GetOutput());

	//relabeler->SetMinimumObjectSize(paramaters->minSize);
	//relabeler->SetInput(labeler->GetOutput());

	labelGeometryImageFilter->CalculatePixelIndicesOn();
	labelGeometryImageFilter->SetInput(labeler->GetOutput());
	//labelGeometryImageFilter->SetIntensityInput(charReader->GetOutput());
	labelGeometryImageFilter->Update();

	std::vector<ShortPixelType> labels = labelGeometryImageFilter->GetLabels();

	CharImageType::SizeType size = charReader->GetOutput()->GetLargestPossibleRegion().GetSize();

	std::vector<int> labelsToUse;

	for (int i=1; i<labels.size(); ++i)
	{
		double eccentricity = labelGeometryImageFilter->GetEccentricity(i);
		int vol = labelGeometryImageFilter->GetVolume(i);
		if (eccentricity>paramaters->eccentricity || vol<paramaters->minSize) continue;
		labelsToUse.push_back(i);
	}

	char buffer[255];
	int idx = paramaters->imageFile.find_last_of("\\");

	//sprintf_s(buffer,"straight_%s", paramaters->imageFile.substr(idx+1).c_str());
	//charWriter->SetFileName(buffer);
	//charWriter->SetImageIO(imageIO);
	//charWriter->SetInput(binaryErode2->GetOutput());
	//charWriter->Update();

	//sprintf_s(buffer,"fill_%s", paramaters->imageFile.substr(idx+1).c_str());
	//charWriter->SetFileName(buffer);
	//charWriter->SetInput(binaryHoleFiller->GetOutput());
	//charWriter->Update();

	//sprintf_s(buffer,"geo_%s", paramaters->imageFile.substr(idx+1).c_str());
	//charWriter->SetFileName(buffer);
	//charWriter->SetInput(labelGeometryImageFilter->GetOutput());
	//charWriter->Update();

	std::vector<Hull> hulls;
	hulls.reserve(labelsToUse.size());
	for (int i=1; i<labelsToUse.size(); ++i)
	{
		LabelGeometryImageFilterType::LabelPointType centerOfMass = 
			labelGeometryImageFilter->GetCentroid(labelsToUse[i]);

		LabelGeometryImageFilterType::LabelIndicesType pixelCoordinates= 
			labelGeometryImageFilter->GetPixelIndices(labelsToUse[i]);
		std::vector<Hull> tempHulls;
		GapStatistic(centerOfMass,pixelCoordinates,tempHulls);

		for (int i=0; i<tempHulls.size(); ++i)
			hulls.push_back(tempHulls[i]);
	}

	std::string outputText = "";
	sprintf_s(buffer,"%d\n",hulls.size());
	outputText += buffer; // Number of hulls in the document
	for (int i=0; i<hulls.size(); ++i)
	{
		sprintf_s(buffer,"(%f,%f)\n",hulls[i].centerOfMass[0],hulls[i].centerOfMass[1]);
		outputText += buffer; // Center of Mass

		sprintf_s(buffer,"%d\n",hulls[i].pixels.size());
		outputText += buffer; // Number of pixelCoordiantes to follow
		for (int j=0; j<hulls[i].pixels.size(); ++j)
		{
			sprintf_s(buffer,"%d,",hulls[i].pixels[j][1]+hulls[i].pixels[j][0]*size[1] +1);
			outputText += buffer;
		}

		outputText += "\n";
	}

	FILE* file = fopen(paramaters->outFile.c_str(),"w");
	fprintf_s(file,"%s",outputText.c_str());
	fclose(file);
	printf("wrote %s\n",paramaters->outFile.c_str());

	return 0;
}