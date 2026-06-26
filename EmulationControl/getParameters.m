function params = getParameters
% This function puts all the physical parametes into a structure so that it is easy to pass around 

% Actuator areas of the emulation cylinder
d_bore = (6)*0.0254; % [in -> m]
d_rod = (3)*0.0254; % [in -> m]
params.A_cap = pi/4*d_bore^2;
params.A_rod = pi/4*(d_bore^2 - d_rod^2);

% Mass of BOTH cylinders
rho_SS = 8000; % [kg/m^3]
params.stroke = 18*.0254; % [m]
params.m = rho_SS * params.A_rod*params.stroke*2; % [kg] mass of both pistons (rho * pi r^2 * 2L)

% linear damping coeff
params.c = 1e5; % [Ns/m]

% Bulk modulus (may be worth doing a pressure dependent beta)
params.beta = 1.6e9;

% Combined displacement of hydraulic pumps
params.D = 53.8 * 100^-3; % [m^3/rev]

% Speed of pump shaft
params.omega = 1500 /60; % [rev/s]

% Hydrostatic charge pressure
params.charge = 2.6e6;

params.swashTimeConstant = .3; % [s]

% Disturbance force
load ../Data_20260624.mat
params.disturbance.time = out.p_AC.Time;
% The cap and rod were mislabeled in this trial
P_rod = out.p_cap.Data;
P_cap = out.p_rod.Data(1:100:end);
    d_rod_pump = (3.5)*0.0254; % [in -> m] diameter of rod
    d_bore_pump = (7)*0.0254; % [in -> m] diameter of bore
    A_cap = pi/4*(d_bore_pump^2);
    A_rod = pi/4*(d_bore_pump^2 - d_rod_pump^2);
params.disturbance.force =  P_cap*A_cap - P_rod*A_rod ;
end
