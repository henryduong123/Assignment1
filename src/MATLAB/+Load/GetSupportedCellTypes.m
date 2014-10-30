function SupportedTypes = GetSupportedCellTypes()

    segAlgTemplate = struct('func',{}, 'params',{});
    frameSegAlgorithms = [struct('func',{@Segmentation.FrameSegmentor}, 'params',{[createParam('imageAlpha', 1.5, [0.9 0.5])]});
                        struct('func',{@Segmentation.FrameSegmentor_Adult}, 'params',{[createParam('imageAlpha', 1.5, [0.9 0.5])]});
                        struct('func',{@Segmentation.FrameSegmentor_Embryonic}, 'params',{[createParam('imageAlpha', 1.5, [0.9 0.5])]})];

    SupportedTypes = struct('name',{[]}, 'segRoutine',{segAlgTemplate}, 'resegRoutines',{segAlgTemplate}, 'trackParams',{[]}, 'leverParams',{[]});
    
    SupportedTypes(1).name = 'Adult';
    SupportedTypes(1).segRoutine = getAlgorithm('Adult', frameSegAlgorithms);
    SupportedTypes(1).resegRoutines(1) = getAlgorithm('Adult', frameSegAlgorithms);
    SupportedTypes(1).trackParams = struct('dMaxCenterOfMass',{40}, 'dMaxConnectComponentTracker',{20});
    SupportedTypes(1).leverParams = struct('timeResolution',{5}, 'maxPixelDistance',{40}, 'maxCenterOfMassDistance',{40}, 'dMaxConnectComponent',{40});
    
    SupportedTypes(2).name = 'Embryonic';
    SupportedTypes(2).segRoutine = getAlgorithm('Embryonic', frameSegAlgorithms);
    SupportedTypes(2).resegRoutines(1) = getAlgorithm('Embryonic', frameSegAlgorithms);
    SupportedTypes(2).trackParams = struct('dMaxCenterOfMass',{80}, 'dMaxConnectComponentTracker',{40});
    SupportedTypes(2).leverParams = struct('timeResolution',{10}, 'maxPixelDistance',{80}, 'maxCenterOfMassDistance',{80}, 'dMaxConnectComponent',{40});

end

function paramStruct = createEmptyParam()
    paramStruct = struct('name',{}, 'default',{}, 'range',{});
end

function paramStruct = createParam(name, defaultValue, resegRange)
    paramStruct = struct('name',{name}, 'default',{defaultValue}, 'range',{resegRange});
end

function algStruct = getAlgorithm(name, segAlgorithms)
    prefixString = 'Segmentation.FrameSegmentor';
    if ( ~strncmpi(prefixString, name, length(prefixString)) )
        name = [prefixString '_' name];
    end
    
    algStruct = [];
    
    funcNames = arrayfun(@(x)(char(x.func)), segAlgorithms, 'UniformOutput',0);
    
    idx = find(strcmpi(name, funcNames),1,'first');
    if ( isempty(idx) )
        return;
    end
    
    algStruct = segAlgorithms(idx);
end
