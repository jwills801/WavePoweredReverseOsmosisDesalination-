% study_refPTO_checkValves.m script m-file
% AUTHORS:
% Jeremy Simmons (email: simmo536@umn.edu)
% University of Minnesota
% Department of Mechanical Engineering
%
% CREATION DATE:
% 6/23/2023
%
% PURPOSE/DESCRIPTION:
% TThis script performs parameter variation studies
% using the model contained in sys_refPTO.m and solved by
% sim_refPTO.m.
% The parameter initiallization functions are called within this
% script before the sim_refPTO.m script is called.
%
% This specific script studies the size of check valves at the WEC-driven
% pump.
%
% FILE DEPENDENCY:
% ./Reference PTO/
%   initialConditionDefault_refPTO
%   parameters_refPTO.m
%   sim_refPTO.m
%   stateIndex_refPTO.m
%   sys_refPTO.m
% ./WEC model/
%   flapModel.m
%   hydroStaticTorque.m
%   parameters_WECmodel.m
% ./WEC model/WECdata
%   nemohResults_vantHoff2009_20180802.mat
%   vantHoffTFCoeff.mat
% ./Solvers/
%   deltaE_NI.m
%   deltaV_NI.m
%   ode1.m
% ./Components/
%   areaFracPWM.m
%   capAccum.m
%   deadVCap.m
%   flowCV.m
%   flowPRV.m
%
% UPDATES:
% 6/23/2023 - Created from study_coulombPTO_dampingStudy.m and 
% run_refPTO.m.
%
% Copyright (C) 2023  Jeremy W. Simmons II
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
addpath('Reference PTO')
addpath('Components')
addpath('Sea States')
addpath('Solvers')
%% %%%%%%%%%%%%   SIMULATION PARAMETERS  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Simulation timeframe
par.Tramp = 250; % [s] excitation force ramp period
par.tstart = 0; %[s] start time of simulation
par.tend = 500; %[s] end time of simulation

% Solver parameters
% par.odeSolverRelTol = 1e-4; % Rel. error tolerance parameter for ODE solver
% par.odeSolverAbsTol = 1e-4; % Abs. error tolerance parameter for ODE solver
par.MaxStep = 5e-5;             % [s] for fixed time solver, this is the step size for solver
par.downSampledStepSize = 1e-2; % [s] specifies time step for data output
if mod(par.downSampledStepSize,par.MaxStep)
    warning('down-sampled time step is not an integer multiple of the maximum step size')
end

% Sea State and Wave construction parameters
% Hs = [2.34 2.64 5.36 2.05 5.84 3.25];
% Tp = [7.31 9.86 11.52 12.71 15.23 16.5];
par.wave.Hs = 2.64;
par.wave.Tp = 9.86;
par.WEC.nw = 1000; % num. of frequency components for harmonic superposition
par.wave.rngSeedPhase = 3; % seed for the random number generator

% load parameters
par = parameters_refPTO(par,...
    'nemohResults_vantHoff2009_20180802.mat','vantHoffTFCoeff.mat');

% Define initial conditions
stateIndex_refPTO % load state indices, provides 'iy_...'
initialConditionDefault_refPTO % default ICs, provides 'y0'

%% Special modifications to base parameters
% par.Sro = 3000; % [m^3]
% par.D_WEC = 0.3;         % [m^3/rad] flap pump displacement
% p_ro_nom = [4.28e6 6.11e6 8e6 6.07e6 8e6 8e6]; % [Pa]
par.control.p_ro_nom = 6.11e6; % [Pa]

% par.ERUconfig.present = 1;
% par.ERUconfig.outlet = 1;

% par.rvIncluded = 1; % RO inlet valve is 1 - present, 0 - absent
% par.rvConfig = (1)*par.rvIncluded; % RO inlet valve is 1 - active, 0 - passive
% dp_rated = 1e5; % [Pa] 
% q_rated = (100)*60/1e3; % [(lpm) -> m^3/s]
% par.kv_rv = q_rated/dp_rated;

%% %%%%%%%%%%%%   Study Variables  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
nVar = 10;
kv = logspace(log10(1e-5),log10(1e-3),nVar);% [m^3/s/Pa] valve coefficient for high-pressure outlet check valve
X = 1.5; % proportion between low and high-pressure check valves

saveSimData = 1; % save simulation data (1) or just output variables (0)

%% %%%%%%%%%%%%   COLLECT DATA  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

parfor iVar = 1:nVar
    param = par; % store individual parameter strucs for parallel compute

    % change design parameter
    param.kvWECout = kv(iVar);
    param.kvWECin = X*kv(iVar);
    
    % run simulation
    ticSIM = tic;
    out = sim_refPTO(y0,param);
    toc(ticSIM)
    
    % Calculate metrics
    it_vec = find(out.t>=par.tstart);
    eff_wecPump(iVar) = mean(out.power.P_wp(it_vec)) ...
                        /mean(out.power.P_WEC(it_vec));
    p_min_wp(iVar) = min([out.p_a;out.p_b]);

    if saveSimData
        simOut(iVar) = out;
    end

end

%% %%%%%%%%%%%%   Save Data  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Save: time in ISO8601
filename = ['data_refPTO_checkValves', ...
            '-',datetime("now",'yyyymmdd')];
save(filename,'-v7.3')

%% %%%%%%%%%%%%   End Computations  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

return

%% %%%%%%%%%%%%   PLOTTING  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

figure
xlabel('flow coefficient, low-pressure (L/s/kPa^{1/2})')
title('Check Valve Sizing Study')
yyaxis left
semilogx(X*kv*1000*sqrt(1000),eff_wecPump)
hold on
ylabel('WEC-driven pump efficiency')
ylim([0 1])

yyaxis right
hold on
semilogx(X*kv*1000*sqrt(1000),1e-3*p_min_wp)
ylabel('minimum pressure in pump (kPA)')

