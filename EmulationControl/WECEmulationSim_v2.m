clear, close all
params = getParameters;


params.control.K = [-22.5 0 0];

ft = 100;
params.traj = makeDesiredTrajectory(ft);
x0 = [-5/100;0;params.charge;1.3*params.charge;0];
[t,y] = ode23t(@(t,states) AllDynamics(t,states,params), [0 ft], x0);

%% plots
plotData

load ../Data_20260624.mat
time = out.p_AC.Time;
x = out.x_wp.Data;
P_cap = out.p_AC.Data;
P_rod = out.p_BD.Data;

figure
subplot(311), plot(time,x,t,y(:,1),params.traj.time,params.traj.xdes), grid, legend('Measured','Modeled','Command'), ylabel('Pos [m]')
subplot(312), plot(time,P_cap/1e6,t,y(:,3)/1e6), grid, ylabel('Cap P [MPa]')% , legend('Measured','Modeled'), ylabel('Cap Pressure [MPa]')
subplot(313), plot(time,P_rod/1e6,t,y(:,4)/1e6), grid, ylabel('Rod P [MPa]'), xlabel('Time [s]')% , legend('Measured','Modeled'), ylabel('Rod Pressure [MPa]')


figure
subplot(221), plot(t,y(:,1),params.traj.time,params.traj.xdes), grid, legend('Actual','Desired'), ylabel('Pos [m]')
subplot(222), plot(t,y(:,2),params.traj.time,params.traj.xdotdes), grid, legend('Actual','Desired'), ylabel('Vel [m/s]')
subplot(223), plot(t,y(:,3:4)/1e6), grid, legend('Cap','Rod'), ylabel('Pressure [MPa]')
subplot(224), plot(t,y(:,5)), grid, ylabel('Frac. Disp.')

function dxdt = AllDynamics(t,states,params)
% Force dxdt to be a column vector
dxdt = NaN(length(states),1);

% unpack states
x = states(1);
xdot = states(2);
P_cap = states(3);
P_rod = states(4);
chi = states(5);

% Control
u = Control(t,states,params);

% Position
dxdt(1) = xdot;

% velocity
dxdt(2) = InertialDynamics(params,t,x,xdot,P_cap,P_rod);

% P_cap
[dxdt(3), dxdt(4)] = PressureDynamics(params,states);

% Fractional Displacement
dxdt(5) = SwashPlateDynamics(params,chi,u);
end

function u = Control(t,states,params)
% unpack states
x = states(1);
xdot = states(2);
P_cap = states(3);
P_rod = states(4);
chi = states(5);

% Interpolate desired trajectories
xdes = interp1(params.traj.time,params.traj.xdes,t);
xdotdes = interp1(params.traj.time,params.traj.xdotdes,t);

% Error in trajectories
e_pos = xdes - x;
e_vel = xdotdes - xdot;

% Calculate Emulation Force
F_emulation = params.A_cap*P_cap - params.A_rod*P_rod;

% Compute Control Input
u = params.control.K*[e_pos;e_vel;F_emulation];

% Saturate control input
u = min(max(u,-1),1);
end

function chiDot = SwashPlateDynamics(params,chi,u)
    chiDot = 1/params.swashTimeConstant * (u-chi);
end

function xddot = InertialDynamics(params,t,x,xdot,P_cap,P_rod)
% Interpolate desired trajectories
F_disurbance = interp1(params.disturbance.time,params.disturbance.force,t);

% Emulation Force
F_emulation = params.A_cap*P_cap - params.A_rod*P_rod;

% Damping Force
F_damping = params.c*xdot;

% Sum of forces
xddot = 1/params.m * (F_emulation - F_damping - F_disurbance);
end

function [dP_cap, dP_rod] = PressureDynamics(params,states)
% unpack states
x = states(1);
xdot = states(2);
cap.P = states(3);
rod.P = states(4);
chi = states(5);

% unpack parameters
beta = params.beta; % Or make this pressure dependent
D = params.D;
omega = params.omega;
stroke = params.stroke;
cap.A = params.A_cap;
rod.A = params.A_rod;

% Flows into cylinder from pump
cap.Qin = -chi*D*omega;
rod.Qin = chi*D*omega;

% Change in volume
cap.dVdt = cap.A*xdot;
rod.dVdt = -rod.A*xdot;

% Volume in each chamber
cap.V = cap.A*(stroke/2+x);
rod.V = rod.A*(stroke/2-x);

% hot oil shuttle valve
[cap.Q_purge,rod.Q_purge] = hotOilShuttle(params,cap,rod);

% Flow from low pressure check valves
cap.Q_charge = lowPressureInletFlow(params,cap);
rod.Q_charge = lowPressureInletFlow(params,rod);

% Pressure Compressibility
dP_cap = beta/cap.V*(cap.Qin-cap.dVdt+cap.Q_charge-cap.Q_purge);
dP_rod = beta/rod.V*(rod.Qin-rod.dVdt+rod.Q_charge-rod.Q_purge);

end

function Q_charge = lowPressureInletFlow(params,side)
netFlow = side.Qin - side.dVdt -side.Q_purge;
P = side.P;
chargeP = params.charge;

%Calculate whether the valve open or closed (smoothly by the tanh function)
checkValvePband = 2e5; % [Pa]
valveOpeningFraction = (tanh((chargeP-P)/checkValvePband)+1)/2;

%If the valve is open, let it cancel out all other flows and volume changes
Q_charge = -netFlow * valveOpeningFraction;

% Flow can only go from the charge line to the chamber, not vice versa
Q_charge = max(0,Q_charge);
end

function [Q_purge_cap,Q_purge_rod] = hotOilShuttle(params,cap,rod)
% Calculate ot oil shuttle opening fraction
P_shuttle_crack = 5e5; % Centering spring cracking pressure
dP_shuttle_band = 2e5; % Smoothing Transition zone width

% If P_rod exceeds P_cap by more than the spring force, open the cap side
cap.HotOil_OpeningFraction = (tanh((rod.P - cap.P - P_shuttle_crack) / dP_shuttle_band) + 1) / 2;

% If P_cap exceeds P_rod by more than the spring force, open the rod side
rod.HotOil_OpeningFraction = (tanh((cap.P - rod.P - P_shuttle_crack) / dP_shuttle_band) + 1) / 2;


% relief valve setting (set slightly lower than charge pressure)
P_purge_relief = 0.9*params.charge;

% Set valve constant for relief valve to give max flow at a given pressure
k_relief = params.D*params.omega/sqrt(10e6);

% Calculate Flow rates
dP = (cap.P - P_purge_relief);
cap.Q_purge = sqrt(abs(dP))*sign(dP) * k_relief * cap.HotOil_OpeningFraction;
dP = (rod.P - P_purge_relief);
rod.Q_purge = sqrt(abs(dP))*sign(dP) * k_relief * rod.HotOil_OpeningFraction;

% Flow should only be able to go out the relief valve (the flow cant be negative)
Q_purge_cap = max(0,  cap.Q_purge);
Q_purge_rod = max(0,  rod.Q_purge);
end