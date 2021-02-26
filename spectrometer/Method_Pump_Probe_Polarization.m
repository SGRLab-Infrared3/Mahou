classdef Method_Pump_Probe_Polarization < Method_Pump_Probe
    methods
        function Scan(obj)
            obj.ScanIsRunning = true;
            
            for ii = 1:2
%                     while obj.ScanIsRunning
%                         pause(1)
%                     end
                if ii == 1 && obj.ScanIsStopping == false
                    obj.source.rotors(2).MoveTo(0);
                    obj.result.polarization = 'ZZZZ';
                elseif ii == 2 && obj.ScanIsStopping == false
                    obj.source.rotors(2).MoveTo(90);
                    obj.result.polarization = 'ZZXX';
                end
                Scan@Method(obj)
%                 pause(5)
            end
            obj.source.rotors(2).MoveTo(0);
            
            obj.ScanIsRunning = false;
            
            obj.ScanIsStopping = false;
        end
    end
end
