classdef Multi_Time_Point_Method < Method
    
    properties
        t2_array;
        nScans_array;
        hFig;
        hChildren;
        t2s_rand;
        nScans_rand;
        current_t2;
        current_nScans;
    end
    
    properties (SetAccess = private)
        temp_t2_array;
        temp_nScans_array;
    end
    
    methods
        function Scan(obj)
            obj.ScanIsRunning = true;
            obj.fileSystem.InitializeLocalOutputFile();
            
            t2s = cell2mat(obj.t2_array);
            nScans = cell2mat(obj.nScans_array);
            
            permIndex = randperm(length(t2s));
            obj.t2s_rand = t2s(permIndex);
            obj.nScans_rand = nScans(permIndex);
            
            for ii = 1:length(t2s)
                if obj.ScanIsStopping == false
%                     while obj.ScanIsRunning
%                         pause(1)
%                     end

                    %set scans
                    obj.current_nScans = obj.nScans_rand(ii);
                    set(obj.handles.editnScans, 'String', num2str(obj.current_nScans));

                    %set t2
                    obj.current_t2 = obj.t2s_rand(ii);
                    set(obj.handles.editt2, 'String', num2str(obj.current_t2));

    %                 Scan@Method(obj)

                    obj.fileSystem.AppendLocalOutputFile(obj.current_nScans, obj.current_t2);

                    pause(5)
                end
            end
            obj.fileSystem.CloseLocalOutputFile();
            obj.fileSystem.SaveOutputFile();
            
            obj.ScanIsRunning = false;
            
            obj.ScanIsStopping = false;
        end
    end
    
    methods % Load & Save Params
        function LoadT2Array(obj)
            name = 't2_array';
            d = Defaults(obj);
            d.LoadDefaults(name);
        end
        
        function SaveT2Array(obj)
            name = 't2_array';
            d = Defaults(obj);
            d.SaveDefaults(name);
        end
        
        function LoadnScansArray(obj)
            name = 'nScans_array';
            d = Defaults(obj);
            d.LoadDefaults(name);
        end
        
        function SavenScansArray(obj)
            name = 'nScans_array';
            d = Defaults(obj);
            d.SaveDefaults(name);
        end
    end
    
    methods % GUI Stuff
        function createParamsButton(obj)
            %get a cell array of the names of the parameters
%             names = fieldnames(obj.PARAMS);
%             %how many parameters are there
%             n_params = length(names);
%             
%             temp = get(obj.hParamsPanel,'Position');
%             y_origin = temp(4); %height of Panel
%             
%             x_pos = 2;
%             y_pos = -2;
%             width = 13;
%             height = 1.54;
%             x_offset = 4;
%             y_offset = 0.21;
            
            uicontrol(obj.hParamsPanel, 'style', 'pushbutton','Tag','pbInputButton',...
                'String', 'Set Time Points', 'Units', 'characters',...
                'Position',[2 0.8365 30 1.7400],... %[x_pos (y_pos+y_origin-(n_params + 1)*(y_offset+height))/2 2*width+x_offset height+0.2]
                'Callback', {@(eventdata, handles) pbInputButton_Callback(obj,eventdata, handles)});
                
            obj.handles = guihandles(obj.handles.figure1);
        end
        
        function createInputWindow(obj)
            obj.hFig = uifigure('Name', 'Time Point Entry', 'Position', [680 500 250 500],...
                'resize', 'off'...
                );
            
            colNames = {'t2', 'nScans'};
            
            obj.temp_t2_array = obj.t2_array;
            obj.temp_nScans_array = obj.nScans_array;

            tbl = table(obj.t2_array, obj.nScans_array, 'VariableNames', {'t2_array', 'nScans_array'});
            
            obj.hChildren{1} = uitable(obj.hFig, 'Position', [15, 73, 220 415],...
                'Tag', 't2_nScans_uitable',...
                'ColumnName', colNames, 'ColumnEditable', true, ...
                'RowName', 'numbered', 'Data', tbl ...
                );
            
            obj.hChildren{2} = uibutton(obj.hFig, 'push', 'Tag', 'pbSave', ...
                'Text', 'Save', 'Position', [135 10 100 28], ...
                'ButtonPushedFcn', {@(eventdata, handles) pbSave_ButtonPushedFcn(obj,eventdata, handles)}...
                );
            
            obj.hChildren{3} = uibutton(obj.hFig, 'push', 'Tag', 'pbCancel',...
                'Text', 'Cancel', 'Position', [15 10 100 28], ...
                'ButtonPushedFcn', {@(eventdata, handles) pbCancel_ButtonPushedFcn(obj,eventdata, handles)}...
                );
            
            obj.hChildren{4} = uibutton(obj.hFig, 'push', 'Tag', 'pbAddRow',...
                'Text', '+', 'Position', [215 50 20 20], 'ToolTip', 'Add a row',...
                'ButtonPushedFcn', {@(eventdata, handles) pbAddRow_ButtonPushedFcn(obj,eventdata, handles)}...
                );
            
            obj.hChildren{5} = uibutton(obj.hFig, 'push', 'Tag', 'pbRemoveRow',...
                'Text', '-', 'Position', [195 50 20 20], 'ToolTip', 'Remove a row',...
                'ButtonPushedFcn', {@(eventdata, handles) pbRemoveRow_ButtonPushedFcn(obj,eventdata, handles)}...
                );
        end
    end
    
    methods % Table interactions
        function ReadTable(obj)
            data = get(obj.hChildren{1}, 'Data');
            
            obj.t2_array = data.t2_array;
            obj.nScans_array = data.nScans_array;
        end
        
        
        function UpdateTable(obj)
            tbl = table(obj.temp_t2_array, obj.temp_nScans_array, 'VariableNames', {'t2_array', 'nScans_array'});
            set(obj.hChildren{1}, 'Data', tbl);            
        end
    end
    
    methods % Callback Functions
        function pbInputButton_Callback(obj, eventdata, handles)
            obj.createInputWindow();
        end
        
        function pbSave_ButtonPushedFcn(obj, eventdata, handles)
            obj.ReadTable();
            
            obj.SaveT2Array();
            obj.SavenScansArray();
            
            delete(obj.hFig);
        end
        
        function pbCancel_ButtonPushedFcn(obj, eventdata, handles)
            delete(obj.hFig)
        end
        
        function pbAddRow_ButtonPushedFcn(obj, eventdata, handles)
            obj.temp_t2_array{end+1} = [];
            obj.temp_nScans_array{end+1} = [];
            
            obj.UpdateTable();
        end
        
        function pbRemoveRow_ButtonPushedFcn(obj, eventdata, handles)
            obj.temp_t2_array = obj.temp_t2_array(1:end-1);
            obj.temp_nScans_array = obj.temp_nScans_array(1:end-1);
            
            obj.UpdateTable();
        end
        
    end
end