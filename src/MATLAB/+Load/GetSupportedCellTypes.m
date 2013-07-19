function SupportedTypes = GetSupportedCellTypes()

    SupportedTypes = struct('name',{[]}, 'segParams',{[]}, 'trackParams',{[]}, 'leverParams',{[]});
    
    SupportedTypes(1).name = 'Adult';
    SupportedTypes(1).segParams = struct('imageAlpha',{1.5});
    SupportedTypes(1).trackParams = struct('dMaxCenterOfMass',{40}, 'dMaxConnectComponentTracker',{20});
    SupportedTypes(1).leverParams = struct('timeResolution',{5}, 'maxPixelDistance',{40}, 'maxCenterOfMassDistance',{40}, 'dMaxConnectComponent',{40});
    
    SupportedTypes(2).name = 'Hemato';
    SupportedTypes(2).segParams = struct('imageAlpha',{1.5}, 'minVolume',{200}, 'maxEccentricity',{1.0}, 'processorUsage',{0.9});
    SupportedTypes(2).trackParams = struct('dMaxCenterOfMass',{80}, 'dMaxConnectComponentTracker',{40});
    SupportedTypes(2).leverParams = struct('timeResolution',{5}, 'maxPixelDistance',{40}, 'maxCenterOfMassDistance',{40}, 'dMaxConnectComponent',{80});
    
    SupportedTypes(3).name = 'Embryonic';
    SupportedTypes(3).segParams = struct('imageAlpha',{1.5});
    SupportedTypes(3).trackParams = struct('dMaxCenterOfMass',{80}, 'dMaxConnectComponentTracker',{40});
    SupportedTypes(3).leverParams = struct('timeResolution',{10}, 'maxPixelDistance',{80}, 'maxCenterOfMassDistance',{80}, 'dMaxConnectComponent',{40});
    
    SupportedTypes(4).name = 'Wehi';
    SupportedTypes(4).segParams = struct('imageAlpha',{1.5});
    SupportedTypes(4).trackParams = struct('dMaxCenterOfMass',{80}, 'dMaxConnectComponentTracker',{40});
    SupportedTypes(4).leverParams = struct('timeResolution',{10}, 'maxPixelDistance',{80}, 'maxCenterOfMassDistance',{80}, 'dMaxConnectComponent',{40});
    
end