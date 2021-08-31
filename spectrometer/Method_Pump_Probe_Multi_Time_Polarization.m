classdef Method_Pump_Probe_Multi_Time_Polarization < Method_Pump_Probe_Polarization & Multi_Time_Point_Method
    
    properties
        scanMethod = 'Scan@Polarization_Method(obj)';
        colNames = {'t2', 'nScans_Para', 'nScans_Perp'};
    end
    
    methods % Constructor Method
        function obj = Method_Pump_Probe_Multi_Time_Polarization(sampler,gate,spect,...
                motors,rotors,handles,hParamsPanel,hMainAxes,hRawDataAxes,hDiagnosticsPanel)
            
            obj = obj@Method_Pump_Probe_Polarization(sampler,gate,spect,...
                motors,rotors,handles,hParamsPanel,hMainAxes,hRawDataAxes,hDiagnosticsPanel);
            
            obj.LoadT2Array();
            obj.LoadnScansArray();
            
            obj.createParamsButton();
        end
    end
end