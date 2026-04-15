% study_refPTO_accum_wActiveRV.m script m-file
% AUTHORS:
% Jeremy Simmons (email: simmo536@umn.edu)
% University of Minnesota
% Department of Mechanical Engineering
%
% CREATION DATE:
% 6/27/2023
%
% PURPOSE/DESCRIPTION:
% This script performs parameter variation studies
% using the model contained in sys_refPTO.m and solved by
% sim_refPTO.m.
% The parameter initiallization functions are called within this
% script before the sim_refPTO.m script is called.
%
% This specific script studies the size of high-pressure accumulators and
% an active valve at the inlet to the RO module for managing pressure rate
% of change.
%
% This script is set up to be run as part of a SLURM job array. The
% following lines are required before this script is called:
%   iVar = ${SLURM_ARRAY_TASK_ID};
%   SS=1;
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
% ./Utilities/
%   statsTimeVar_cdf.m
%
% UPDATES:
% 6/27/2023 - Created from study_refPTO_switchingValve.m
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
% clear
% clc
addpath('WEC model') 
addpath(['WEC model' filesep 'WECdata']) 
addpath('Reference PTO')
addpath('Components')
addpath('Sea States')
addpath('Solvers')
addpath('Utilities')
%% %%%%%%%%%%%%   SIMULATION PARAMETERS  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Simulation timeframe
par.Tramp = 250; % [s] excitation force ramp period
par.tstart = 0; %[s] start time of simulation
par.tend = 2000; %[s] end time of simulation

% Solver parameters
% par.odeSolverRelTol = 1e-4; % Rel. error tolerance parameter for ODE solver
% par.odeSolverAbsTol = 1e-4; % Abs. error tolerance parameter for ODE solver
par.MaxStep = 5e-5;             % [s] for fixed time solver, this is the step size for solver
par.downSampledStepSize = 1e-2; % [s] specifies time step for data output
if mod(par.downSampledStepSize,par.MaxStep)
    warning('down-sampled time step is not an integer multiple of the maximum step size')
end

% Sea State and Wave construction parameters
Hs = [2.34 2.64 5.36 2.05 5.84 3.25];
Tp = [7.31 9.86 11.52 12.71 15.23 16.5];
par.wave.Hs = Hs(SS);
par.wave.Tp = Tp(SS);
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
p_ro_nom = [4.28e6 6.11e6 8e6 6.07e6 8e6 8e6]; % [Pa]
par.control.p_ro_nom = p_ro_nom(SS);
par.duty_sv = 0;

% Configuration
par.ERUconfig.present = 1;
par.ERUconfig.outlet = 1;

par.rvConfig.included = 1; % RO inlet valve is 1 - present, 0 - absent
par.rvConfig.active = (1)*par.rvConfig.included; % RO inlet valve is 1 - active, 0 - passive
% dp_rated = 1e5; % [Pa] 
% q_rated = (100)*60/1e3; % [(lpm) -> m^3/s]
% par.kv_rv = q_rated/dp_rated;

par.D_pm = (1000)*1e-6/(2*pi); % [(cc/rev) -> m^3/rad]  Motor displacement
par.w_pm_max = (3600)/60*2*pi; % [(rpm) -> rad/s] maximum speed of motor

%% %%%%%%%%%%%%   Study Variables  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% total accumulator volume
% ditribution between motor inlet and RO inlet
% max valve coefficient

nVar1 = 15;
Vtotal = 1e-3*logspace(log10(5e3),log10(20e3),nVar1);% [L->m^3] total accumulator volume
nVar2 = 9;
X = linspace(0.1,0.5,nVar2); % [-] accumulator volume distribution 1 - all at RO inlet, 0 - all at motor inlet
nVar3 = 10;
kv = 1/sqrt(1000)/1000*logspace(log10(0.5e0),log10(1.5e1),nVar3);% [(L/s/kPa^0.5)->m^3/s/Pa^0.5] max valve coefficient for ripple control valve

[meshVar.Vtotal, meshVar.X, meshVar.kv] = meshgrid(Vtotal,X,kv);
Vtotal_mesh = meshVar.Vtotal(:);
X_mesh = meshVar.X(:);
kv_mesh = meshVar.kv(:);

nVar = length(Vtotal_mesh);

saveSimData = 1; % save simulation data (1) or just output variables (0)

%% %%%%%%%%%%%%   COLLECT DATA  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% change design parameter
par.kv_rv = kv_mesh(iVar);
par.Vc_h = (1 - X_mesh(iVar))*Vtotal_mesh(iVar);
par.Vc_ro = X_mesh(iVar)*Vtotal_mesh(iVar);

% run simulation
ticSIM = tic;
out = sim_refPTO(y0,par);
toc(ticSIM)

% Calculate metrics
it_vec = find(out.t>=par.tstart);
% max rate of change in pressure
% 97th percentile ratof change
% power loss from valve
% power loss through PRVs
% permeate production
% 
q_permMean = mean(out.q_perm(it_vec));
PP_WEC = mean(out.power.P_WEC(it_vec));
PP_wp = mean(out.power.P_wp(it_vec));
PP_rv = mean(out.power.P_rv(it_vec));
PP_hPRV = mean(out.power.P_hPRV(it_vec));
PP_roPRV = mean(out.power.P_roPRV(it_vec));
dpdt_max = max(abs(out.dydt(it_vec,iyp_ro)));

dist_dpdt = statsTimeVar_cdf(out.t(it_vec),abs(out.dydt(it_vec,iyp_ro)));
dpdt_97 = dist_dpdt.xi(find(dist_dpdt.f > 0.97,1,'first'));

if ~saveSimData
    clear out
end



%% %%%%%%%%%%%%   Save Data  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
timeStamp = datetime("now",'format','yyyy-MM-dd''T''HH:mm'); % time in ISO8601

% Save data
filename = ['data_refPTO_accum_wActiveRV', ...
            '_',char(datetime("now",'Format','yyyyMMdd')), ...
            '_',num2str(SS,leadingZeros(999)), ...
            '_',num2str(iVar,leadingZeros(nVar))];
save(filename,'-v7.3')

%% %%%%%%%%%%%%   End Computations  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

poolobj = gcp('nocreate'); delete(poolobj);

return
