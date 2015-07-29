function SupportedTypes = GetSupportedCellTypes()

    SupportedTypes = struct('name',{[]}, 'segParams',{[]}, 'trackParams',{[]}, 'leverParams',{[]});
    
    SupportedTypes(1).name = 'Adult';
    SupportedTypes(1).segParams = struct('imageAlpha',{1.5});
    SupportedTypes(1).trackParams = struct('dMaxCenterOfMass',{40}, 'dMaxConnectComponentTracker',{20});
    SupportedTypes(1).leverParams = struct('timeResolution',{5}, 'maxPixelDistance',{40}, 'maxCenterOfMassDistance',{40}, 'dMaxConnectComponent',{40});
    
    SupportedTypes(2).name = 'Embryonic';
    SupportedTypes(2).segParams = struct('imageAlpha',{1.5});
    SupportedTypes(2).trackParams = struct('dMaxCenterOfMass',{80}, 'dMaxConnectComponentTracker',{40});
    SupportedTypes(2).leverParams = struct('timeResolution',{10}, 'maxPixelDistance',{80}, 'maxCenterOfMassDistance',{80}, 'dMaxConnectComponent',{40});
end
