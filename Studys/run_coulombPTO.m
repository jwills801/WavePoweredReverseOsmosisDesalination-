% run_coulombPTO.m script m-file
% AUTHORS:
% Jeremy Simmons (email: simmo536@umn.edu)
% University of Minnesota
% Department of Mechanical Engineering
%
% CREATION DATE:
% 06/23/2021
%
% PURPOSE/DESCRIPTION:
% This script serves as a shell for running a single simulation
% using the model contained in sys_coulombPTO.m and run by solved by 
% sim_coulombPTO.m.
% The parameter initiallization fuction are called within this
% script before the sim_coulombPTO.m script is called.
%
% FILE DEPENDENCY:
% sys_coulombPTO.m
% sim_coulombPTO.m
% parameters_coulombPTO.m
%
% UPDATES:
% 06/23/2021 - Created.
% 08/02/2022 - added ramp period to par struct and included tstart so that
% ramp ends at t=0;
%
% Copyright (C) 2022  Jeremy W. Simmons II
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
clear
% clc
addpath('WEC model') 
addpath(['WEC model' filesep 'WECdata']) 
addpath('Coulomb damping PTO') 
addpath('Sea States')
addpath('Solvers')
%% %%%%%%%%%%%%   SIMULATION PARAMETERS  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Simulation timeframe
par.Tramp = 250; % [s] excitation force ramp period
par.tstart = 0; %[s] start time of simulation
par.tend = 2000; %[s] end time of simulation

% Solver parameters
par.odeSolverRelTol = 1e-4; % Rel. error tolerance parameter for ODE solver
par.odeSolverAbsTol = 1e-4; % Abs. error tolerance parameter for ODE solver
par.MaxStep = 1e-2;

% Sea State and Wave construction parameters
% Hs = [2.34 2.64 5.36 2.05 5.84 3.25];
% Tp = [7.31 9.86 11.52 12.71 15.23 16.5];
par.wave.Hs = 2.64;
par.wave.Tp = 9.86;
par.WEC.nw = 1000; % num. of frequency components for harmonic superposition 
par.wave.rngSeedPhase = 3; % seed for the random number generator

% load parameters
par = parameters_coulombPTO(par,...
    'nemohResults_vantHoff2009_20180802.mat','vantHoffTFCoeff.mat');

% Define initial conditions
y0 = [  0, ...
        0, ...
        zeros(1,par.WEC.ny_rad)];

%% Special modifications to base parameters
par.Tcoulomb = 3e6; % [Nm] PTO reaction torque

%% %%%%%%%%%%%%   COLLECT DATA  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% run simulation
tic
out = sim_coulombPTO(y0,par);
toc

%% %%%%%%%%%%%%   PLOTTING  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
figure
plot(out.t,out.waveElev)
xlabel('time (s)')
ylabel('elevation (m)')
title('Wave Elevation')

%%
figure
plot(out.t,out.theta)
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

mean(-out.T_pto(:).*out.theta_dot(:))

