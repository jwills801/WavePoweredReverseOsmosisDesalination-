
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
figure, plot(params.traj.time,params.traj.xdes,time,x,t,y(:,1)), grid, legend('Command','Measured','Modeled'), ylabel('Pos [m]')

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
Qin = -chi*params.D*params.omega;
dVdt = params.A_cap*xdot;
V = params.A_cap*(params.stroke/2+x);
dxdt(3) = CompressibilityEq(params,P_cap,V,Qin,dVdt);

% P_rod
Qin = chi*params.D*params.omega;
dVdt = -params.A_rod*xdot;
V = params.A_rod*(params.stroke/2-x);
dxdt(4) = CompressibilityEq(params,P_rod,V,Qin,dVdt);

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
F_disurbance = 0*interp1(params.disturbance.time,params.disturbance.force,t);

% Emulation Force
F_emulation = params.A_cap*P_cap - params.A_rod*P_rod;

% Damping Force
F_damping = params.c*xdot;

% Sum of forces
xddot = 1/params.m * (F_emulation - F_damping - F_disurbance);
end

function dP = CompressibilityEq(params,P,V,Qin,dVdt)
beta = params.beta; % Or make this pressure dependent

% If the pressure is too low, there will be flow from the charge pump
% This flow will be enough to make up the difference in flow
% This flow is turned on and off smoothly by the tanh function
    % When P is low, the second term is zero
    % When P is high, the second term is one
Q_charge = max(0,-(Qin-dVdt) * (tanh((params.charge-P)/10)+1)/2);

dP = beta/V*(Qin-dVdt+Q_charge);
end