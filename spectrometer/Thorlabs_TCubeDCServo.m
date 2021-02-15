classdef Thorlabs_TCubeDCServo < Thorlabs_DCServo
    
    properties(Constant, Hidden)
        % path to DLL files (edit as appropriate)
        MOTORPATHDEFAULT='C:\Program Files\Thorlabs\Kinesis\';
        
        % DLL files to be loaded
        CONTROLSDLL = 'Thorlabs.MotionControl.Controls.dll';
        DEVICEMANAGERDLL='Thorlabs.MotionControl.DeviceManagerCLI.dll';
        DEVICEMANAGERCLASSNAME='Thorlabs.MotionControl.DeviceManagerCLI.DeviceManagerCLI';
        GENERICMOTORDLL='Thorlabs.MotionControl.GenericMotorCLI.dll';
        GENERICMOTORCLASSNAME='Thorlabs.MotionControl.GenericMotorCLI.GenericMotorCLI';
        DCSERVODLL='Thorlabs.MotionControl.TCube.DCServoCLI.dll';
        DCSERVOCLASSNAME='Thorlabs.MotionControl.TCube.DCServoCLI.TCubeDCServo';
        
        % Default intitial parameters
        DEFAULTVEL=10;           % Default velocity
        DEFAULTACC=10;           % Default acceleration
        TPOLLING=250;            % Default polling time
        TIMEOUTSETTINGS=7000;    % Default timeout time for settings change
        TIMEOUTMOVE=100000;      % Default time out time for motor move
    end
    
    properties
        % These properties are within Matlab wrapper
        isConnected=false;           % Flag set if device connected
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
    
    properties (Hidden,SetAccess = immutable)
        Tag;
    end
    
    properties (Hidden)
        % These are properties within the .NET environment.
        deviceNET;                   % Device object within .NET
        motorSettingsNET;            % motorSettings within .NET
        currentDeviceSettingsNET;    % currentDeviceSetings within .NET
        deviceInfoNET;               % deviceInfo within .NET
    end
    
    methods (Hidden)
        function obj = InitializeDeviceNET(obj, serialNumber)
           obj.deviceNET = Thorlabs.MotionControl.TCube.DCServoCLI.TCubeDCServo.CreateTCubeDCServo(serialNumber); 
        end
    end
    
    methods
        function isConnected = get.isConnected(obj)
            try
                isConnected = boolean(obj.deviceNET.IsConnected());
            catch
                isConnected = false;
            end
        end
        
        function serialNumber = get.serialNumber(obj)
            serialNumber = char(obj.deviceNET.DeviceID);          % update serial number
        end
        
        function controllerName = get.controllerName(obj)
            controllerName = char(obj.deviceInfoNET.Name);        % update controleller name
        end
        
        function controllerDescription = get.controllerDescription(obj)
            controllerDescription = char(obj.deviceInfoNET.Description);  % update controller description
        end
        
        function stageName = get.stageName(obj)
            stageName = char(obj.motorSettingsNET.DeviceSettingsName);    % update stagename
        end
        
        function acceleration = get.acceleration(obj)
            velocityParams = obj.deviceNET.GetVelocityParams();             % update velocity parameter
            acceleration = System.Decimal.ToDouble(velocityParams.Acceleration); % update acceleration parameter
        end
        
        function maxVelocity = get.maxVelocity(obj)
            velocityParams = obj.deviceNET.GetVelocityParams();             % update velocity parameter
            maxVelocity = System.Decimal.ToDouble(velocityParams.MaxVelocity);   % update max velocit parameter
        end
        
        function minVelocity = get.minVelocity(obj)
            velocityParams = obj.deviceNET.GetVelocityParams();             % update velocity parameter
            minVelocity = System.Decimal.ToDouble(velocityParams.MinVelocity);   % update Min velocity parameter
        end
        
        function position = get.position(obj)
            position = System.Decimal.ToDouble(obj.deviceNET.Position);   % Read current device position
            position = position - obj.center;
            if strcmp(obj.stageName, 'PRMTZ8/M')
                if round(position, 2) < 0
                    position = 360 + position;
                elseif round(position, 2) == 360
                    position = 0;
                end
            end 
        end
        
        function position = get.absolutePosition(obj)
            position = System.Decimal.ToDouble(obj.deviceNET.Position);   % Read current device position
        end
        
        function isBusy = get.isBusy(obj)
            isBusy = obj.deviceNET.IsDeviceBusy;
        end
    end
end