function par = parameters_HIL(par)
%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% parameters_HIL.m function m-file
% AUTHORS: 
% Jeremy Simmons (email: simmo536@umn.edu)
% University of Minnesota
% Department of Mechanical Engineering
%
% CREATION DATE:
% 5/21/2025
%
% PURPOSE/DESCRIPTION:
% This function loads parameters for the HIL SCADA into the "par"
% structure.
%
% FILE DEPENDENCY:
%
% UPDATES:
% 5/21/2025 - created.
%
% Copyright (C) 2025  Jeremy W. Simmons II
% 
%   This program is free software: you can redistribute it and/or modify
%   it under the terms of the GNU General Public License as published by
%   the Free Software Foundation, either version 3 of the License, or
%   (at your option) any later version.
% 
%   This program is distributed in the hope that it will be useful,
%   but WITHOUT ANY WARRANTY; without even the implied warranty of
%   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
%   GNU General Public License for more details.
% 
%   You should have received a copy of the GNU General Public License
%   along with this program. If not, see <https://www.gnu.org/licenses/>.
%
%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    %% WEC-driven pump
    par.WECpump.positiveLimit = (9)*0.0254; % [in -> m] positive extent of travel limit
    par.WECpump.negativeLimit = -(9)*0.0254; % [in -> m] negative extent of travel limit

    par.WECpump.positiveCtrlLimit = (10 ...
)*0.0254; % [in -> m] positive extent of travel limit for control
    par.WECpump.negativeCtrlLimit = -(10)*0.0254; % [in -> m] negative extent of travel limit for control

    % conversion of angular to linear motion and force: reference scale vs.
    % HIL system
     % reference scale
    D_WEC = 0.3;         % [m^3/rad] flap pump displacement
     % HIL
    par.scale_sys = 0.0102;
    d_rod_pump = (3.5)*0.0254; % [in -> m] diameter of rod
    d_bore_pump = (7)*0.0254; % [in -> m] diameter of bore
    par.WECpump.A_cap = pi/4*(d_bore_pump^2);
    par.WECpump.A_rod = pi/4*(d_bore_pump^2 - d_rod_pump^2);
    
    bias = 0.5;
    A_eff = bias*par.WECpump.A_cap + (1-bias)*par.WECpump.A_rod;

    par.WECpump.ang2lin = D_WEC*par.scale_sys/A_eff;


    %% Actuator Control
    
    % Actuator/Actuator Control
    d_bore_act = (6)*0.0254; % [in -> m]
    d_rod_act = (3)*0.0254; % [in -> m]
    par.actuator.A_cap = pi/4*d_bore_act^2;
    par.actuator.A_rod = pi/4*(d_bore_act^2 - d_rod_act^2);

    % Danfoss H1T/Actuator Control
    par.H1T.D = 53.8; % [cc/rev]

     % cut-in duty (PWM) of electronic displacement control unit
      % Pump 1
    par.H1T.P1.posCutIn = 0.01;
    par.H1T.P1.negCutIn = 0.01;

      % Pump 2
    par.H1T.P2.posCutIn = 0.01;
    par.H1T.P2.negCutIn = 0.01;

    % Position control gains
    ku = (0.1)*1.21;
    Tu = 0.3255;
    switch 1
        case 1 % P
            par.H1T.kp = ku*(0.5);
            par.H1T.ki = ku/Tu*(0);
            par.H1T.kd = ku*Tu*(0);
        case 2 % PI
            par.H1T.kp = ku*(0.45);
            par.H1T.ki = ku/Tu*(0.54);
            par.H1T.kd = ku*Tu*(0);
        case 3 % PD
            par.H1T.kp = ku*(0.8);
            par.H1T.ki = ku/Tu*(0);
            par.H1T.kd = ku*Tu*(0.1);
        case 4 % PID 1 ("classic")
            par.H1T.kp = ku*(0.6);
            par.H1T.ki = ku/Tu*(1.2);
            par.H1T.kd = ku*Tu*(0.075);
        case 5 % PID 2 (Pessen Integral Rule)
            par.H1T.kp = ku*(0.7);
            par.H1T.ki = ku/Tu*(1.75);
            par.H1T.kd = ku*Tu*(0.105);
        case 6 % PID 3 ("some overshoot")
            par.H1T.kp = ku*(0.3333);
            par.H1T.ki = ku/Tu*(0.6667);
            par.H1T.kd = ku*Tu*(0.1111);
        case 7 % PID 4 ("no overshoot")
            par.H1T.kp = ku*(0.2);
            par.H1T.ki = ku/Tu*(0.4);
            par.H1T.kd = ku*Tu*(0.06667);
    end

    % fractional displacement bias
    par.H1T.P1.fBias = 0.5; % 0 to 0.5
    par.H1T.P2.fBias = 0.5; % 0 to 0.5

    %% Charge Pump Control
    % Speed limits of charge pump
    par.charge.nMax = 3600; % [rpm] upper limit
    par.charge.nMin = 0; % [rpm] lower limit

    % Experimental fit pump curve
    par.charge.cn = 209.3; % [Pa/(rev/s)^(1/2)]
    par.charge.cq = -9.58e10; % [Pa/(m^3/s)^(1/2)]
    
    % Pressure control gains
    par.charge.kp = 1;
    par.charge.ki = 1;
    par.charge.kd = 0;

    %% Motor/Gen. Control
    % Speed limits of motor and generator
    par.gen.nMax = 3600; % [rpm] upper limit
    par.gen.nMin = 0; % [rpm] lower limit
    % Pressure control gains
    par.gen.kp = (5e-4)*60/(2*pi); % [(rad/s)/Pa -> rpm/Pa]
    par.gen.ki = 0;
    par.gen.kd = 0;

    %% ERU Control
    % Speed limits of the energy recovery unit
    par.ERU.nMax = 3600; % [rpm] upper limit
    par.ERU.nMin = 0; % [rpm] lower limit
    % Recovery control gains
    par.ERU.kp = 1;
    par.ERU.ki = 1;
    par.ERU.kd = 0;

end