% run_coulombPTO.m script m-file
% AUTHORS:
% Jackson Wills (email: wills224@umn.edu)
% University of Minnesota
% Department of Mechanical Engineering
%
% CREATION DATE:
% 02/18/2026
%
% PURPOSE/DESCRIPTION:
% This script serves as a shell for running a a grid search of torque
% values using the model contained in sys_coulombPTO.m and run by 
% solved by sim_coulombPTO.m.
% The parameter initiallization fuction are called within this
% script before the sim_coulombPTO.m script is called.
%
% FILE DEPENDENCY:
% sys_coulombPTO.m
% sim_coulombPTO.m
% parameters_coulombPTO.m
%
% UPDATES:
% 02/18/2026 - Created.
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
clear, close all
% clc
addpath('..\WEC model') 
addpath(['..\WEC model' filesep 'WECdata']) 
addpath('..\Coulomb damping PTO') 
addpath('..\Sea States')
addpath('..\Solvers')
%% %%%%%%%%%%%%   SIMULATION PARAMETERS  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Solver parameters
par.odeSolverRelTol = 1e-4; % Rel. error tolerance parameter for ODE solver
par.odeSolverAbsTol = 1e-4; % Abs. error tolerance parameter for ODE solver
par.MaxStep = 1e-2;

% Sea State and Wave construction parameters
Hs = [2.34 2.64 5.36 2.05 5.84 3.25];
Tp = [7.31 9.86 11.52 12.71 15.23 16.5];
seaStateInd =5;
par.wave.Hs = Hs(seaStateInd);
par.wave.Tp = Tp(seaStateInd);
par.WEC.nw = 1000; % num. of frequency components for harmonic superposition 
par.wave.rngSeedPhase = 3; % seed for the random number generator

% load parameters
par = parameters_coulombPTO(par,...
    'nemohResults_vantHoff2009_20180802.mat','vantHoffTFCoeff.mat');

% Simulation timeframe
par.Tramp = par.wave.Tp*5; % [s] excitation force ramp period
par.tstart = 0; %[s] start time of simulation
par.tend = par.wave.Tp*20; % [s] end time of simulation

% Define initial conditions
y0 = [  0, ...
        0, ...
        zeros(1,par.WEC.ny_rad)];

% Define torque values to try
Tvals = linspace(0,20,21)*1e6; % [Nm] PTO reaction torque

% Initialize average power vector
P = NaN(size(Tvals));
posContraint = zeros(size(Tvals));

%% Loop over torque values (grid search)
for Tind = 1:length(Tvals)

%% Special modifications to base parameters
par.Tcoulomb = Tvals(Tind); % [Nm] PTO reaction torque

%% %%%%%%%%%%%%   COLLECT DATA  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% run simulation
tic
out = sim_coulombPTO(y0,par);
toc

% Average power
P(Tind) = mean(-out.T_pto(:).*out.theta_dot(:));

% If position constraints are not met, make this infeasibile
if max(out.theta*180/pi)>45
    posContraint(Tind) = 1;
end
end

figure
plot(Tvals,P), xlabel('PTO Torque'), ylabel('Average Power')

figure
plot(Tvals,posContraint), xlabel('PTO Torque'), ylabel('Violated Position constraints')

% Optimal Torque
[Popt,TindOpt] = max(P);
Topt = Tvals(TindOpt);

%% %%%%% RESULTS %%%%%%%%
disp(['Hs: ', num2str(par.wave.Hs), ', Tp: ', num2str(par.wave.Tp), 'Nm , Topt: ', num2str(Topt/1e6),'e6, Power: ', num2str(Popt/1e3), 'kW'])

% Tabulated Results
    % Optimal torques are intentionally 1 sigfig
    % since optimal torques are sensitive to simulation duration
% Hs: 2.34, Tp: 7.31, Topt: 4e6Nm, Power: 125kW
% Hs: 2.64, Tp: 9.86, Topt: 4e6Nm, Power: 200kW
% Hs: 5.36, Tp: 11.52, Topt: 7e6Nm, Power: 100kW
% Hs: 2.05, Tp: 12.71, Topt: 2e6Nm, Power: 200kW
% Hs: 5.84, Tp: 15.23, Topt: 6e6Nm, Power: 1250kW
% Hs: 3.25, Tp: 16.5, Topt: 3e6Nm, Power: 450kW

% Results from Jeremys study (data_coulombPTO_dampingStudy_6SS_20230724_slim.mat)
    % for i =1:6
    %     figure
    %     plot(T_c_data(i,:)/1e6,PP_w_data(i,:)/1e3)
    %     ylabel('Power [kW]'), xlabel('Torque [MNm]')
    %     title(['Hs = ', num2str(Hs(i)), ', Ts = ', num2str(Tp(i))])
    % end
% Hs: 2.34, Tp: 7.31, Topt: 4.9e6Nm, Power: 200kW
% Hs: 2.64, Tp: 9.86, Topt: 4.4e6Nm, Power: 340kW
% Hs: 5.36, Tp: 11.52, Topt: 7.7e6Nm, Power: 1590kW
% Hs: 2.05, Tp: 12.71, Topt: 2e6Nm, Power: 270kW
% Hs: 5.84, Tp: 15.23, Topt: 6.8e6Nm, Power: 1570kW
% Hs: 3.25, Tp: 16.5, Topt: 3.5e6Nm, Power: 600kW    


%% %%%%%%%%%%%%   PLOTTING Individual Runs  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
figure
plot(out.t,out.waveElev)
xlabel('time (s)')
ylabel('elevation (m)')
title('Wave Elevation')

%%
figure
plot(out.t,out.theta*180/pi)
xlabel('time (s)')
ylabel('position (rad)')
% ylim([-pi/2 pi/2])
% xlim([0 2])

%%
figure
xlabel('time (s)')

yyaxis left
hold on
plot(out.t,out.theta_dot)
ylabel('angular velocity (rad/s)')
% ylim(10*[-pi/2 pi/2])

yyaxis right
hold on
plot(out.t,1e-6*out.T_pto)
ylabel('torque, PTO (MNm)')
ylim(2*1e-6*[-par.Tcoulomb par.Tcoulomb])
% xlim([0 2])

%%
figure
hold on
plot(out.t,1e-6*out.T_wave)
plot(out.t,1e-6*out.T_pto)
plot(out.t,1e-6*out.T_rad)
ylabel('torque (MNm)')

