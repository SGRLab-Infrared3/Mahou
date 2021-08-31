classdef Method_2d_quasiphase_Multi_Time_Point < Method_2d_quasiphase & Multi_Time_Point_Method
    
    properties
        scanMethod = 'Scan@Method(obj)'; % '';
        colNames = {'t2', 'nScans'};
    end
    
    methods
        function obj = Method_2d_quasiphase_Multi_Time_Point(sampler,gate,spect,...
                motors,rotors,handles,hParamsPanel,hMainAxes,hRawDataAxes,hDiagnosticsPanel)
            
            obj = obj@Method_2d_quasiphase(sampler,gate,spect,...
                motors,rotors,handles,hParamsPanel,hMainAxes,hRawDataAxes,hDiagnosticsPanel);
            
            obj.LoadT2Array();
            obj.LoadnScansArray();
            
            obj.createParamsButton();
            
        end
    end
    
end