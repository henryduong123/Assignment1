function SupportedTypes = GetSupportedCellTypes()
    SupportedTypes = [];
    
    SupportedTypes = addCellType(SupportedTypes, 'Adult',...
                        'segRoutine',setAlgorithm(@Segmentation.FrameSegmentor_Adult, setParamValue('imageAlpha', 1.5)),...
                        'resegRoutine',setAlgorithm(@Segmentation.FrameSegmentor_Adult, setParamRange('imageAlpha', 1.0,0.5,5)),...
                        'trackParams',struct('dMaxCenterOfMass',{40}, 'dMaxConnectComponentTracker',{20}),...
                        'leverParams',struct('timeResolution',{5}, 'maxPixelDistance',{40}, 'maxCenterOfMassDistance',{40}, 'dMaxConnectComponent',{40}),...
                        'channelParams',struct('channelOrder',{[1]}, 'channelColor',{[1 1 1]}, 'channelFluor',{[false]}));
    
    SupportedTypes = addCellType(SupportedTypes, 'Embryonic',...
                        'segRoutine',setAlgorithm(@Segmentation.FrameSegmentor_Embryonic, setParamValue('imageAlpha', 1.5)),...
                        'resegRoutine',setAlgorithm(@Segmentation.FrameSegmentor_Embryonic, setParamRange('imageAlpha', 1.0,0.5,5)),...
                        'trackParams',struct('dMaxCenterOfMass',{80}, 'dMaxConnectComponentTracker',{40}),...
                        'leverParams',struct('timeResolution',{5}, 'maxPixelDistance',{80}, 'maxCenterOfMassDistance',{80}, 'dMaxConnectComponent',{40}),...
                        'channelParams',struct('channelOrder',{[1]}, 'channelColor',{[1 1 1]}, 'channelFluor',{[false]}));
    
    % TODO: Move channel params and some lever params into metadata structure and parse directly from microscope data.
end

function cellTypes = addCellType(cellTypes, typeName, varargin)
    supportedFields = {'segRoutine', 'resegRoutine','trackParams','leverParams','channelParams'};
    
    defaultType = getDefaultCellType();
    
    newCellType = struct('name',{[]}, 'segRoutine',{[]}, 'resegRoutines',{[]}, 'trackParams',{[]}, 'leverParams',{[]}, 'channelParams',{[]});
    newCellType.name = typeName;
    
    if ( mod(length(varargin),2) > 0 )
        error('Expected key-value pairs in addCellType');
    end
    
    cellFields = fieldnames(newCellType);
    
    bUseDefaults = true(length(cellFields),1);
    bUseDefaults(1) = false;
    
    for i=1:2:length(varargin)
        if ( ~ischar(varargin{i}) )
            error('Non-string field names are unsupported!');
        end
        
        fieldIdx = find(strcmpi(varargin{i},supportedFields));
        if ( isempty(fieldIdx) )
            warning(['Unsupported field: ' varargin{i} ' (ignored).']);
            continue;
        end
        
        bUseDefaults(fieldIdx+1) = false;
        keyName = supportedFields{fieldIdx};
        if ( strcmpi(keyName, 'resegRoutine') )
            newCellType.resegRoutines = [newCellType.resegRoutines varargin{i+1}];
        else
            newCellType.(keyName) = varargin{i+1};
        end
    end
    
    defFields = cellFields(bUseDefaults);
    for i=1:length(defFields)
        newCellType.(defFields{i}) = defaultType.(defFields{i});
    end
    
    cellTypes = [cellTypes; newCellType];
end

function defaultTypeStruct = getDefaultCellType()
    defaultTypeStruct = struct('name',{'Default'},...
        'segRoutine',{setAlgorithm(@Segmentation.FrameSegmentor, setParamValue('imageAlpha', 1.5))},...
        'resegRoutines',{setAlgorithm(@Segmentation.FrameSegmentor, setParamRange('imageAlpha', 1.0,0.5,5))},...
        'trackParams',{struct('dMaxCenterOfMass',{80}, 'dMaxConnectComponentTracker',{40})},...
        'leverParams',{struct('timeResolution',{5}, 'maxPixelDistance',{80}, 'maxCenterOfMassDistance',{80}, 'dMaxConnectComponent',{40})},...
        'channelParams',{struct('channelOrder',{[1]}, 'channelColor',{[1 1 1]}, 'channelFluor',{[false]})});
end

function algorithmStruct = setAlgorithm(funcPtr, varargin)
    emptyParam = struct('name',{}, 'value',{});
    algorithmStruct = struct('func',{funcPtr}, 'params',{emptyParam});
    
    for i=1:length(varargin)
        if ( ~checkParamStruct(varargin{i}) )
            error('Expected valid parameter structure use setParamValue() or setParamRange() functions.');
        end
        
        algorithmStruct.params = [algorithmStruct.params varargin{i}];
    end
end

function paramStruct = setParamValue(paramName, value)
    paramStruct = struct('name',{paramName}, 'value',{value});
end

function paramStruct = setParamRange(paramName, startValue, endValue, numSteps)
    paramStruct = struct('name',{paramName}, 'value',{linspace(startValue,endValue,numSteps)});
end

function bValidParam = checkParamStruct(inStruct)
    bValidParam = false;
    if ( ~isstruct(inStruct) )
        return;
    end
    
    if ( ~isfield(inStruct, 'name') )
        return;
    end
    
    if ( ~isfield(inStruct, 'value') )
        return;
    end
    
    bValidParam = true;
end
