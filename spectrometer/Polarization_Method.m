classdef Polarization_Method < Method

    methods
        function Scan(obj)
            global method
            obj.ScanIsRunning = true;
            
            for ii = 1:2
%                 while obj.ScanIsRunning
%                     pause(1)
%                 end
                if ii == 1 && obj.ScanIsStopping == false
                    obj.source.rotors(2).MoveTo(0);
                    obj.result.polarization = 'ZZZZ';
                    set(obj.handles.editnScans, 'String', get(obj.handles.editnScans_Para, 'String'));
                    if contains(class(method), 'Multi_Time')
                        obj.fileSystem.AppendLocalOutputFile(obj.current_nScans_Para, obj.current_t2, obj.result.polarization);
                    end
                elseif ii == 2 && obj.ScanIsStopping == false
                    obj.source.rotors(2).MoveTo(90);
                    obj.result.polarization = 'ZZXX';
                    set(obj.handles.editnScans, 'String', get(obj.handles.editnScans_Perp, 'String'));
                    if contains(class(method), 'Multi_Time')
                        obj.fileSystem.AppendLocalOutputFile(obj.current_nScans_Perp, obj.current_t2, obj.result.polarization);
                    end
                end
%                 Scan@Method(obj)
                pause(1)
                
                
            end
            obj.source.rotors(2).MoveTo(0);
            
            obj.ScanIsRunning = false;
            
%             obj.ScanIsStopping = false;
        end
    end
end