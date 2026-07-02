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
params.beta = 1.8e9;

% Combined displacement of hydraulic pumps
params.D = 53.8 * 100^-3; % [m^3/rev]

% Speed of pump shaft
params.omega = 1500 /60; % [rev/s]

% Hydrostatic charge pressure
params.charge = 2.6e6;

params.swashTimeConstant = .3; % [s]

params.control.K = getControl(params);
end

function K = getControl(params)
%% unpack parameters
c= params.c;
m = params.m;
beta = params.beta;
A_cap = params.A_cap;
A_rod = params.A_rod;
D= params.D;
omega= params.omega;
stroke = params.stroke;

A = [0 1 0;
    0 -c/m 1/m;
    0 -2*beta/stroke*(A_cap+A_rod) 0];
B = [0;0;-2*beta/stroke*2*D*omega];
Bd = [0;-1/m;0];

% Placing poles
K = place(A,B,[-5,-500+1500i,-500-1500i]);

% LQR
Q = 1000*[1 0 0; 0 1 0; 0 0 0];
R = 1;
sys = ss(A,B,[1 0 0],[]);
[K,~,~] = lqr(sys,Q,R);

for i = 1:length(K) K(i), end

% K = [-30 -10 -1e-4];

A_CL = A-B*K;
B_CL = B*K; B_CL = B_CL(:,1);
OL_poles = eig(A)
CL_poles = eig(A_CL)

sys_CL = ss(A_CL,B_CL,[1 0 0],[]);
% step(sys_CL)

% figure, plot(real(OL_poles),imag(OL_poles),'*')
figure, plot(real(OL_poles),imag(OL_poles),'*',real(CL_poles),imag(CL_poles),'*'), legend('Open Loop','Closed Loop')
grid

if 0
%%
magVal = logspace(2,4,10);
Kvals = NaN(10,3);
for i = 1:10
    Q = magVal(i)*[1 0 0; 0 1 0; 0 0 0];
    R = 1;
    sys = ss(A,B,[1 0 0],[]);
    [Kvals(i,:),~,~] = lqr(sys,Q,R);
end
figure,semilogx(magVal,Kvals(:,1:2))
figure,semilogx(magVal,Kvals(:,3))
%%
end
end

