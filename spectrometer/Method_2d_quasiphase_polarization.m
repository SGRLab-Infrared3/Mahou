classdef Method_2d_quasiphase_polarization < Method_2d_quasiphase
    
    methods
        function obj = Method_2d_quasiphase_polarization(sampler,gate,spect,...
                motors,rotors,handles,hParamsPanel,hMainAxes,hRawDataAxes,hDiagnosticsPanel)
            %constructor
            
            if nargin == 0
                %put actions here for when constructor is called with no arguments,
                %which will serve as defaults.
                obj.sample = 1;
                return
            elseif nargin == 1
                %If item in is a method class object, just return that object.
                if isa(obj,'Method_Test_Phasing')
                    return
                elseif isa(obj,'Method')
                    %what to do if it is a different class but still a Method? How does
                    %that work? take FPAS and IO values and handles, delete input object,
                    %and call constructor with those input arguments (one level of
                    %recursion I guess). Will that work?
                    return
                end
            end
            
            %obj.nBins = obj.PARAMS.bin_max - obj.PARAMS.bin_min +1;
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
            
            obj.initialPosition(1) = obj.source.motors{1}.GetPosition;
            obj.initialPosition(2) = obj.source.motors{2}.GetPosition;
            
            Initialize(obj);
            
            %     InitializeFreqAxis(obj);
            %     InitializeParameters(obj,hParamsPanel);
            %     ReadParameters(obj);
            %     InitializeData(obj);
            %     InitializeMainPlot(obj);
            %     InitializeRawData(obj);
            %     InitializeDiagnostics(obj);
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