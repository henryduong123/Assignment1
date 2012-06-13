#include "Segmentation.h"
#include "itkTIFFImageIO.h"

int segmentation(std::string imageFilepath, std::string outputPath, float imageAlpha, int minVolume)
{
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
	//BinaryFillholeImageFilterType::Pointer  binaryHoleFiller =  BinaryFillholeImageFilterType::New();
	ConnectedComponentFilterType::Pointer	labeler =			ConnectedComponentFilterType::New();
	RelabelComponentFilterType::Pointer		relabeler =			RelabelComponentFilterType::New();
	LabelGeometryImageFilterType::Pointer	labelGeometryImageFilter = LabelGeometryImageFilterType::New();
	
	StructuringElementType		structuringElement;

	charReader->SetImageIO(imageIO);
	charReader->SetFileName(imageFilepath);
	charReader->Update();

	histogramGenerator->SetNumberOfBins(256);
	histogramGenerator->SetInput(charReader->GetOutput());
	histogramGenerator->Compute();

	thresholdCalculator->SetInput(histogramGenerator->GetOutput());
	thresholdCalculator->Update();

	itk::SimpleDataObjectDecorator<double>* thresh = thresholdCalculator->GetOutput();
	float threshold = thresh->Get();

	threshold *= imageAlpha;

	thresholdFilter->SetLowerThreshold(threshold);
	thresholdFilter->SetOutsideValue(0);
	thresholdFilter->SetInsideValue(-1);
	thresholdFilter->SetUpperThreshold(255);
	thresholdFilter->SetInput(charReader->GetOutput());

	structuringElement.SetRadius(3);
	structuringElement.CreateStructuringElement();

	binaryErode->SetKernel(structuringElement);
	binaryErode->SetInput(thresholdFilter->GetOutput());

	binaryDilate->SetKernel(structuringElement);
	binaryDilate->SetInput(binaryErode->GetOutput());

	binaryDilate2->SetKernel(structuringElement);
	binaryDilate2->SetInput(binaryDilate->GetOutput());

	binaryErode2->SetKernel(structuringElement);
	binaryErode2->SetInput(binaryDilate2->GetOutput());

	//binaryHoleFiller->SetInput(binaryErode2->GetOutput());
	//binaryHoleFiller->SetFullyConnected(false);

	//charWriter->SetFileName("D:\\Desktop\\holefiller.tiff");
	//charWriter->SetImageIO(imageIO);
	//charWriter->SetInput(binaryHoleFiller->GetOutput());
	//charWriter->Update();

	labeler->SetInput(binaryDilate2->GetOutput());

	relabeler->SetMinimumObjectSize(minVolume);
	relabeler->SetInput(labeler->GetOutput());

	labelGeometryImageFilter->CalculatePixelIndicesOn();
	labelGeometryImageFilter->SetInput(relabeler->GetOutput());
	labelGeometryImageFilter->SetIntensityInput(charReader->GetOutput());
	labelGeometryImageFilter->Update();

	std::vector<ShortPixelType> labels = labelGeometryImageFilter->GetLabels();

	CharImageType::SizeType size = charReader->GetOutput()->GetLargestPossibleRegion().GetSize();

	std::vector<int> labelsToUse;

	for (int i=1; i<labels.size(); ++i)
	{
		double eccentricity = labelGeometryImageFilter->GetEccentricity(i);
		if (eccentricity>0.75) continue;
		labelsToUse.push_back(i);
	}

	char buffer[255];
	std::string outputText = "";
	sprintf_s(buffer,"%d\n",labelsToUse.size());
	outputText += buffer; // Number of hulls in the document
	for (int i=0; i<labelsToUse.size(); ++i)
	{
		LabelGeometryImageFilterType::LabelPointType centerOfMass = 
			labelGeometryImageFilter->GetCentroid(labelsToUse[i]);
		sprintf_s(buffer,"(%f,%f)\n",centerOfMass[0],centerOfMass[1]);
		outputText += buffer; // Center of Mass

		LabelGeometryImageFilterType::LabelIndicesType pixelCoordinates= 
			labelGeometryImageFilter->GetPixelIndices(labelsToUse[i]);
		sprintf_s(buffer,"%d\n",pixelCoordinates.size());
		outputText += buffer; // Number of pixelCoordiantes to follow
		for (int j=0; j<pixelCoordinates.size(); ++j)
		{
			sprintf_s(buffer,"%d,",pixelCoordinates[j][1]+pixelCoordinates[j][0]*size[1] +1);
			outputText += buffer;
		}

		outputText += "\n";
	}

	FILE* file = fopen(outputPath.c_str(),"w");
	fprintf_s(file,"%s",outputText.c_str());
	fclose(file);
	printf("wrote %s\n",outputPath.c_str());

	return 0;
}