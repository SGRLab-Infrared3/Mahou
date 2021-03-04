classdef Thorlabs_DCServo < handle & matlab.mixin.Heterogeneous
    
    properties(Abstract, Constant, Hidden)
        % path to DLL files (edit as appropriate)
        MOTORPATHDEFAULT;
        
        % DLL files to be loaded
        CONTROLSDLL;
        DEVICEMANAGERDLL;
        DEVICEMANAGERCLASSNAME
        GENERICMOTORDLL
        GENERICMOTORCLASSNAME
        DCSERVODLL
        DCSERVOCLASSNAME
        
        % Default intitial parameters
        DEFAULTVEL           % Default velocity
        DEFAULTACC           % Default acceleration
        TPOLLING           % Default polling time
        TIMEOUTSETTINGS    % Default timeout time for settings change
        TIMEOUTMOVE      % Default time out time for motor move
    end
    
    properties
        servoNum
        direction
        genMot
    end
    
    properties (Abstract, Dependent)
        % These properties are within Matlab wrapper
        isConnected;           % Flag set if device connected
        isBusy;                      % Is the device currently busy
        serialNumber;                % Device serial number
        controllerName;              % Controller Name
        controllerDescription        % Controller Description
        stageName;                   % Stage Name
        position;                    % Position relative to the center point
        absolutePosition;            % Absolute position
        acceleration;                % Acceleration
        maxVelocity;                 % Maximum velocity limit
        minVelocity;                 % Minimum velocity limit
    end
    
    properties
        center=0;                      % Used as home position. All positions are relative to this value;
    end
    
    properties (Abstract, Hidden, SetAccess = immutable)
        Tag;
    end
    
    properties (Abstract, Hidden)
        % These are properties within the .NET environment.
        deviceNET;                   % Device object within .NET
        motorSettingsNET;            % motorSettings within .NET
        currentDeviceSettingsNET;    % currentDeviceSetings within .NET
        deviceInfoNET;               % deviceInfo within .NET
    end
    
    properties (SetAccess = private)
        hPanel;     %handle to the panel to draw controls in
        hChildren;
        handles;
    end
    
    methods
        function obj = Thorlabs_DCServo(serialNumber, direction, tagname)
            % START HERE
            global rotors
            fprintf(1, '\nInitalizing Thorlabs DC servo for %s ... \n', tagname)
            obj.servoNum = length(rotors)+1;
            try   % Load in DLLs if not already loaded
                NET.addAssembly([obj.MOTORPATHDEFAULT, obj.DEVICEMANAGERDLL]);
                NET.addAssembly([obj.MOTORPATHDEFAULT, obj.DCSERVODLL]);
                obj.genMot = NET.addAssembly([obj.MOTORPATHDEFAULT, obj.GENERICMOTORDLL]);
                
                %build a tag from the last input
                if strcmp(tagname(1:4),'edit')
                    obj.Tag = tagname(5:end);
                else
                    obj.Tag = tagname;
                end
                
                Thorlabs.MotionControl.DeviceManagerCLI.DeviceManagerCLI.BuildDeviceList();  % Build device list
                serialNumbersNet = Thorlabs.MotionControl.DeviceManagerCLI.DeviceManagerCLI.GetDeviceList(); % Get device list
                serialNumbers=cell(ToArray(serialNumbersNet)); % Convert serial numbers to cell array
                
                if ~any(strcmp(serialNumbers, serialNumber))
                    error('Stage with specified serial number not found')
                end
                
                obj.serialNumber = serialNumber;
                
                obj = obj.InitializeDeviceNET(serialNumber);
                
                obj.deviceNET.Connect(serialNumber);
                
                
                if ~obj.deviceNET.IsSettingsInitialized() % Wait for IsSettingsInitialized via .NET interface
                    obj.deviceNET.WaitForSettingsInitialized(obj.TIMEOUTSETTINGS);
                end
                
                if ~obj.deviceNET.IsSettingsInitialized() % Cannot initialise device
                    error('Unable to initialise device: S/N %s', obj.serialNumber);
                end
                
                obj.deviceNET.StartPolling(obj.TPOLLING);   % Start polling via .NET interface
                obj.motorSettingsNET = obj.deviceNET.LoadMotorConfiguration(obj.serialNumber); % Get motorSettings via .NET interface
                obj.currentDeviceSettingsNET = obj.deviceNET.MotorDeviceSettings;     % Get currentDeviceSettings via .NET interface
                obj.deviceInfoNET = obj.deviceNET.GetDeviceInfo();                    % Get deviceInfo via .NET interface
                
                obj.direction = direction;
                
                enumHandle = obj.genMot.AssemblyHandle.GetType('Thorlabs.MotionControl.GenericMotorCLI.Settings.RotationSettings+RotationDirections');
                if strcmp(direction, 'forward')
                    MotDir = enumHandle.GetEnumValues().Get(1); % 1 stands for "Forwards"
                elseif strcmp(direction, 'backward')
                    MotDir = enumHandle.GetEnumValues().Get(2); % 2 stands for "Backwards"
                else
                    warning('SGRLAB:ThorLabs_DCServo:BadInputArgument','The input %s for direction is not supported. Using "forward"',direction);
                    MotDir = enumHandle.GetEnumValues().Get(1); % 1 stands for "Forwards"
                end
                obj.currentDeviceSettingsNET.Rotation.RotationDirection=MotDir;   % Set motor direction to be 'forwards'
                LoadResetPosition(obj);
                obj.Home();
                
                if obj.servoNum == 1
                    rotors = obj;
                else
                    rotors(obj.servoNum) = obj;
                end
                
                fprintf(1, 'Done.\n');
            catch err
                fprintf(1, '\n')
                warning('Spectrometer:Thorlabs_DCServo', [sprintf('Failed to connect to Thorlabs DC servo %s: S/N %s\n', tagname, serialNumber), err.message])
            end
        end
        
        function delete(obj) % Disconnect device
            global rotors
            fprintf(1, 'Cleaning up Thorlabs DC servo: %s ... ', obj.Tag)
            if obj.isConnected
                obj.deviceNET.StopPolling();  % Stop polling device via .NET interface
                obj.deviceNET.DisconnectTidyUp();
                obj.deviceNET.Disconnect();   % Disconnect device via .NET interface
            end
            DeleteControls(obj); %remove gui elements
            fprintf(1, 'Done.\n');
            
            for ii = 1:length(rotors)
                if strcmp(rotors(ii).serialNumber, obj.serialNumber)
                    delete(rotors(ii));
                    rotors(ii) = [];
                    break
                end
            end
        end
        
        function Reset(obj)    % Reset device
            if obj.isConnected
                try
                    obj.deviceNET.ClearDeviceExceptions();  % Clear exceptions vua .NET interface
                    obj.deviceNET.ResetConnection(obj.serialNumber) % Reset connection via .NET interface
                catch err
                    fprintf(1, '\n')
                    warning('Spectrometer:Thorlabs_DCServo', ['Unable to reset device ',obj.serialNumber,'.\n', err.message])
                end
            end
        end
        
        function Home(obj)              % Home device (must be done before any device move
            if obj.isConnected
                try
                    workDone=obj.deviceNET.InitializeWaitHandler();     % Initialise Waithandler for timeout
                    fprintf(1, 'Homing Stage ... ')
                    obj.deviceNET.Home(workDone);                       % Home devce via .NET interface
                    obj.deviceNET.Wait(obj.TIMEOUTMOVE);                  % Wait for move to finish
                    fprintf(1, 'Done.\nMoving stage to set zero-point ... \n');
                    obj.MoveTo(0);
                    fprintf(1, 'Done.\n')
                catch err
                    fprintf(1, '\n')
                    warning('Spectrometer:Thorlabs_DCServo', ['Unable to home device ',obj.serialNumber,'.\n', err.message])
                end
            end
        end
        
        function MoveTo(obj,position)     % Move to absolute position
            if obj.isConnected
                try
                    while obj.isBusy
                        pause(obj.TPOLLING/1000);
                    end
                    
                    while position >= 360
                        position = position - 360;
                    end
                    
                    workDone = obj.deviceNET.InitializeWaitHandler(); % Initialise Waithandler for timeout
                    obj.deviceNET.MoveTo(position + obj.center, workDone);       % Move devce to position via .NET interface
                    %                 obj.deviceNET.Wait(obj.TIMEOUTMOVE);              % Wait for move to finish
                    
                    pause(obj.TPOLLING./1000);
                    
                    while obj.deviceNET.IsDeviceBusy
                        obj.UpdatePositionTextbox();
                        pause(obj.TPOLLING./1000);
                    end
                    
                    obj.UpdatePositionTextbox();
                    
                catch % Device faile to move
                    fprintf(1, '\n')
                    warning('Spectrometer:Thorlabs_DCServo', ['Unable to move device ', obj.serialNumber, ' to ', num2str(position), '.\n', err.message])
                end
            end
        end
        
        function JogForward(obj)
            if obj.isConnected
                try
                    while obj.isBusy
                        pause(obj.TPOLLING./1000);
                    end
                    
                    if strcmp(obj.direction, 'forward')
                        MotDir = Thorlabs.MotionControl.GenericMotorCLI.MotorDirection.Forward;
                    elseif strcmp(obj.direction, 'backward')
                        MotDir = Thorlabs.MotionControl.GenericMotorCLI.MotorDirection.Backward;
                    end
                    workDone = obj.deviceNET.InitializeWaitHandler(); % Initialise Waithandler for timeout
                    obj.deviceNET.MoveJog(MotDir, workDone);
                    %                 obj.deviceNET.Wait(obj.TIMEOUTMOVE);
                    
                    pause(obj.TPOLLING./1000);
                    
                    while obj.deviceNET.IsDeviceBusy
                        obj.UpdatePositionTextbox();
                        pause(obj.TPOLLING./1000);
                    end
                    obj.UpdatePositionTextbox();
                    
                catch err % Device failed to jog
                    fprintf(1, '\n')
                    warning('Spectrometer:Thorlabs_DCServo', ['Unable to jog device ',obj.serialNumber,' forward.\n', err.message])
                end
            end
        end
        
        function JogBackward(obj)
            if obj.isConnected
                try
                    while obj.isBusy
                        pause(obj.TPOLLING./1000);
                    end
                    
                    if strcmp(obj.direction, 'forward')
                        MotDir = Thorlabs.MotionControl.GenericMotorCLI.MotorDirection.Backward;
                    elseif strcmp(obj.direction, 'backward')
                        MotDir = Thorlabs.MotionControl.GenericMotorCLI.MotorDirection.Forward;
                    end
                    workDone = obj.deviceNET.InitializeWaitHandler(); % Initialise Waithandler for timeout
                    obj.deviceNET.MoveJog(MotDir, workDone);
                    pause(obj.TPOLLING./1000);
                    
                    while obj.deviceNET.IsDeviceBusy
                        obj.UpdatePositionTextbox();
                        pause(obj.TPOLLING./1000);
                    end
                    obj.UpdatePositionTextbox();
                    
                catch err % Device failed to jog
                    fprintf(1, '\n')
                    warning('Spectrometer:Thorlabs_DCServo', ['Unable to jog device ',obj.serialNumber,' forward.\n', err.message])
                end
            end
        end
        
        function Stop(obj) % Stop the motor moving (needed if set motor to continous)
            if obj.isConnected
                try
                    obj.deviceNET.Stop(obj.TIMEOUTMOVE); % Stop motor movement via.NET interface
                catch err
                    fprintf(1, '\n')
                    warning('Spectrometer:Thorlabs_DCServo', ['Unable to stop device ',obj.serialNumber,'.\n', err.message])
                end
            end
        end
        
        function SetVelocity(obj, varargin)  % Set velocity and acceleration parameters
            if obj.isConnected
                try
                    velpars = obj.deviceNET.GetVelocityParams(); % Get existing velocity and acceleration parameters
                    switch(nargin)
                        case 1  % If no parameters specified, set both velocity and acceleration to default values
                            velpars.MaxVelocity = obj.DEFAULTVEL;
                            velpars.Acceleration = obj.DEFAULTACC;
                        case 2  % If just one parameter, set the velocity
                            velpars.MaxVelocity = varargin{1};
                        case 3  % If two parameters, set both velocitu and acceleration
                            velpars.MaxVelocity = varargin{1};  % Set velocity parameter via .NET interface
                            velpars.Acceleration = varargin{2}; % Set acceleration parameter via .NET interface
                    end
                    if System.Decimal.ToDouble(velpars.MaxVelocity)>25  % Allow velocity to be outside range, but issue warning
                        warning('Velocity >25 deg/sec outside specification')
                    end
                    if System.Decimal.ToDouble(velpars.Acceleration)>25 % Allow acceleration to be outside range, but issue warning
                        warning('Acceleration >25 deg/sec2 outside specification')
                    end
                    obj.deviceNET.SetVelocityParams(velpars); % Set velocity and acceleration paraneters via .NET interface
                catch err
                    fprintf(1, '\n')
                    warning('Spectrometer:Thorlabs_DCServo', ['Unable to set velocity of device ',obj.serialNumber,'.\n', err.message])
                end
            end
        end
        
        function SetCenter(obj)
            if obj.isConnected
                try
                    obj.center = round(obj.absolutePosition, 2);
                    
                    %save that to a file
                    obj.SaveResetPosition;
                catch err
                    fprintf(1, '\n')
                    warning('Spectrometer:Thorlabs_DCServo', ['Unable to save new center for device ',obj.serialNumber,'.\n', err.message])
                end
            end
        end
        
        function LoadResetPosition(obj)
            name = 'center';
            d = Defaults(obj);
            d.LoadDefaults(name);
        end
        
        function SaveResetPosition(obj)
            name = 'center';
            d = Defaults(obj);
            d.SaveDefaults(name);
        end
    end
    
    methods
        function InitializeGui(obj,hPanel)
            fprintf(1, '\nInitializing Thorlabs DC Servo GUI panel for %s ... ', obj.Tag)
            obj.hPanel = hPanel; %has to come first
            obj.DrawControls; %has to come second
            obj.UpdatePositionTextbox;
            obj.handles = guihandles(obj.hPanel);    %last
            fprintf(1, 'Done.\n');
        end
        
        function DeleteControls(obj)
            delete(obj.hChildren);
        end
        
        function DrawControls(obj)
            obj.hChildren(1) = uicontrol(obj.hPanel,...
                'Style', 'text',...
                'Tag', sprintf('textServo%i', obj.servoNum),...
                'String', sprintf('%s:', obj.Tag),...
                'HorizontalAlignment', 'left',...
                'Units', 'characters',...
                'Position', [1.6923076923076925 3.5454545454545454-2.54*(obj.servoNum-1) 15.0 1.3030303030303032]...
                );
            
            obj.hChildren(2) = uicontrol(obj.hPanel,...
                'Style', 'pushbutton',...
                'Tag', sprintf('pbJogBackServo%i', obj.servoNum),...
                'String', '<',...
                'HorizontalAlignment', 'center',...
                'Units', 'characters',...
                'Position', [16.6, 3.307692307692308-2.54*(obj.servoNum-1), 3.8, 1.8461538461538463],...
                'Callback', {@(hObject,eventdata) pbJogBack_Callback(obj,hObject,eventdata)}...
                );
            
            obj.hChildren(3) = uicontrol(obj.hPanel,...
                'Style', 'edit',...
                'Tag', sprintf('editTxtServo%i', obj.servoNum),...
                'String', num2str(obj.position),...
                'HorizontalAlignment', 'right',...
                'units', 'characters',...
                'Position', [20.400000000000002 3.307692307692308-2.54*(obj.servoNum-1) 8.4 1.8461538461538463],...
                'Callback', {@(hObject,eventdata) editPositionTextbox_Callback(obj,hObject,eventdata)}...
                );
            obj.hChildren(4) = uicontrol(obj.hPanel,...
                'Style', 'pushbutton',...
                'Tag', sprintf('pbJogForwardServo%i', obj.servoNum),...
                'String', '>',...
                'HorizontalAlignment', 'center',...
                'Units', 'characters',...
                'Position', [29.0, 3.307692307692308-2.54*(obj.servoNum-1), 3.8, 1.8461538461538463],...
                'Callback', {@(hObject,eventdata) pbJogForward_Callback(obj,hObject,eventdata)}...
                );
            
            obj.hChildren(5) = uicontrol(obj.hPanel,...
                'Style', 'pushbutton',...
                'Tag', sprintf('pbGoServo%i', obj.servoNum),...
                'String', 'go',...
                'HorizontalAlignment', 'center',...
                'Units', 'characters',...
                'Position', [33.30769230769231, 3.3333333333333335-2.54*(obj.servoNum-1), 7.615384615384613, 1.8484848484848482],...
                'Callback', {@(hObject,eventdata) pbGo_Callback(obj,hObject,eventdata)}...
                );
            
            obj.hChildren(6) = uicontrol(obj.hPanel,...
                'Style', 'pushbutton',...
                'Tag', sprintf('pbResetServo%i', obj.servoNum),...
                'String', 'reset',...
                'HorizontalAlignment', 'center',...
                'Units', 'characters',...
                'Position', [41.30769230769231, 3.3333333333333335-2.54*(obj.servoNum-1), 6.769230769230774, 1.8484848484848482],...
                'Callback', {@(hObject,eventdata) pbReset_Callback(obj,hObject,eventdata)}...
                );
            
            %finally update handles
            obj.handles = guihandles(obj.hPanel);
        end
        
        function UpdatePositionTextbox(obj)
            if ~isempty(obj.hChildren)
                set(obj.handles.(['editTxtServo' num2str(obj.servoNum)]),...
                    'String', sprintf('%3.2f', obj.position));
            else
                fprintf(1, '%s Position: %3.2f\n', obj.Tag, obj.position);
            end
        end
        
        function out = ReadPositionTextbox(obj)
            out = str2double(get(obj.handles.(['editTxtServo' num2str(obj.servoNum)]),'String'));
        end
        
        
    end
    
    methods (Access = public)
        function pbJogBack_Callback(obj, hObject, eventdata)
            obj.JogBackward();
        end
        
        function pbJogForward_Callback(obj, hObject, eventdata)
            obj.JogForward();
        end
        
        function pbGo_Callback(obj, hObject, eventdata)
            newPos = obj.ReadPositionTextbox();
            obj.MoveTo(newPos);
        end
        
        function editPositionTextbox_Callback(obj, hObject, eventdata)
            newPos = obj.ReadPositionTextbox();
            obj.MoveTo(newPos);
        end
        
        function pbReset_Callback(obj, hObject, eventdata)
            obj.SetCenter;
            obj.UpdatePositionTextbox;
        end
    end
    
    methods (Abstract)
        InitializeDeviceNET(obj);
    end
end