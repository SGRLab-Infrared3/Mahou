classdef Rotor < handle
    
       properties(Constant, Hidden)
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
        % These properties are within Matlab wrapper
        isConnected;           % Flag set if device connected
        serialNumber;                % Device serial number
        controllerName;              % Controller Name
        controllerDescription        % Controller Description
        stageName;                   % Stage Name
        position;                    % Position relative to the center point
        absolutePosition;            % Absolute position
        acceleration;                % Acceleration
        maxVelocity;                 % Maximum velocity limit
        minVelocity;                 % Minimum velocity limit
        center=0;                      % Used as home position. All positions are relative to this value;
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
    
end