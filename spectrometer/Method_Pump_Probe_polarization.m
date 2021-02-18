classdef Method_Pump_Probe_polarization < Method_Pump_Probe
    
    methods
        function obj = Method_Pump_Probe_polarization(sampler,gate,spect,...
                motors,rotors,handles,hParamsPanel,hMainAxes,hRawDataAxes,hDiagnosticsPanel)
            %constructor
            
            obj.nChopStates = obj.nSignals/obj.nArrays;
            
            if nargin == 0
                %put actions here for when constructor is called with no arguments,
                %which will serve as defaults.
                obj.sample = 1;
                return
            elseif nargin == 1
                %If item in is a method class object, just return that object.
                if isa(obj,'Method_Pump_Probe')
                    return
                elseif isa(obj,'Method')
                    %what to do if it is a different class but still a Method? How does
                    %that work? take FPAS and IO values and handles, delete input object,
                    %and call constructor with those input arguments (one level of
                    %recursion I guess). Will that work?
                    return
                end
            end
            
            obj.source.sampler = sampler; %is there a better way?
            obj.source.gate = gate;
            obj.source.spect = spect;
            obj.source.motors = motors;
            obj.source.rotors = rotors;
            obj.hMainAxes = hMainAxes;
            obj.hParamsPanel = hParamsPanel;
            obj.hRawDataAxes = hRawDataAxes;
            obj.hDiagnosticsPanel = hDiagnosticsPanel;
            obj.handles = handles;
            obj.saveData = true;
            
            Initialize(obj);
            
            %     InitializeFreqAxis(obj);
            %     InitializeParameters(obj,hParamsPanel);
            %     ReadParameters(obj);
            %     InitializeData(obj);
            %     InitializeMainPlot(obj);
            %     InitializeRawData(obj);
            %     InitializeDiagnostics(obj);
            
            %inherited public methods:
            %ScanStop
        end
    end
    
    methods
        function Scan(obj)
            for ii = 1:2
                if ii == 1
                    obj.source.rotors(2).MoveTo(0);
                    obj.result.polarization = 'ZZZZ';
                else
                    obj.source.rotors(2).MoveTo(90);
                    obj.result.polarization = 'ZZXX';
                end
                Scan@Method(obj)
                obj.source.rotors(2).MoveTo(0);
            end
        end
    end
end