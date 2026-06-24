d_bore_act = (6)*0.0254; % [in -> m]
d_rod_act = (3)*0.0254; % [in -> m]
A_cap = pi/4*d_bore_act^2;
A_rod = pi/4*(d_bore_act^2 - d_rod_act^2);

m = 8000 * A_rod*2; % [kg] mass of both pistons (rho * pi r^2 * L)
c = 1e3; % [Ns/m]
beta = 1.8e9;
V_cap = A_cap*0.25;
V_rod = A_rod*0.25;
D = 53.8 * 100^-3; % [m^3/rev]
omega = 3500 /60; % [rev/s]

tau = .1; % time constant of swash plate
ku = 1;

A = [0 1 0 0 0;
     0 -c/m A_cap/m -A_rod/m 0;
     0 -beta/V_cap*A_cap 0 0 -beta/V_cap*D*omega;
     0 beta/V_rod*A_rod 0 0 beta/V_rod*D*omega;
     0 0 0 0 -1/tau];
B = [0;0;0;0;ku/tau];
Bd = [0;-1/m;0;0;0];

sys = ss(A,B,[1 0 0 0 0],0);
% rlocus(sys)

K = [-10 1 0 0 0];
OL_poles = eig(A);
CL_poles = eig(A-B*K)

figure, plot(real(OL_poles),imag(OL_poles),'*')
figure, plot(real(OL_poles),imag(OL_poles),'*',real(CL_poles),imag(CL_poles),'*'), legend('Open Loop','Closed Loop')
grid

%%
A_c = [0 1 0;
    0 -c/m 1/m;
    0 -beta/4*(A_cap+A_rod) 0];
B_c = [0;0;-beta/2*D*omega];
Bd = [0;-1/m;0];

K_c = place(A_c,B_c,[-5,-5+250i,-5-250i])
K_c = [-20 0 -3e-6];
OL_poles = eig(A_c);
CL_poles = eig(A_c-B_c*K_c)

figure, plot(real(OL_poles),imag(OL_poles),'*')
figure, plot(real(OL_poles),imag(OL_poles),'*',real(CL_poles),imag(CL_poles),'*'), legend('Open Loop','Closed Loop')
grid

%%
params.A = A;
params.B = B;
tf = 10;
dt = .01;
params.t = 0:dt:tf;
params.xdes = 0*params.t -.5;
params.xdotdes = 0*params.t;
params.Ki = -10;
params.Kp = 0;
params.kf = -1e-5;
x0 = [0 0 0e5 0 0];

[t,y] = ode23(@(t,y) func(t,y,params),[0 tf],x0);


close all
figure
subplot(221), plot(t,y(:,1),params.t,params.xdes), grid, legend('Actual','Desired')
subplot(222), plot(t,y(:,2),params.t,params.xdotdes), grid, legend('Actual','Desired')
subplot(223), plot(t,y(:,3:4)), grid, legend('Cap','Rod')
subplot(224), plot(t,y(:,5))

% [t2,y2] = forwardEuler(@func,x0,params,tf,1e-5);
% figure
% subplot(221), plot(t2,y2(:,1),params.t,params.xdes), grid, legend('Actual','Desired')
% subplot(222), plot(t2,y2(:,2),params.t,params.xdotdes), grid, legend('Actual','Desired')
% subplot(223), plot(t2,y2(:,3:4)), grid, legend('Cap','Rod')
% subplot(224), plot(t2,y2(:,5))

function dxdt = func(t,x,params)
d_bore_act = (6)*0.0254; % [in -> m]
d_rod_act = (3)*0.0254; % [in -> m]
A_cap = pi/4*d_bore_act^2;
A_rod = pi/4*(d_bore_act^2 - d_rod_act^2);
F_emulation = A_cap*x(3) - A_rod*x(4);


    xdes = interp1(params.t,params.xdes,t);
    xdotdes = interp1(params.t,params.xdotdes,t);
    
    x_desired = [xdes; xdotdes; 0; 0; 0];
    e = x_desired - x; 

    u = params.Ki*e(1) + params.Kp*e(2) + params.kf*F_emulation;
    u = min([1,u]);
    u = max([-1 u]);

    dxdt = params.A*x + params.B*u;

    if x(3)<0 && dxdt(3) < 0
        dxdt(3) = 0;
    end
   if x(4)<0 && dxdt(4) < 0
        dxdt(4) = 0;
    end
    
end

function [t,y] = forwardEuler(dxdt,x0,params,tf,dt)
t = 0:dt:tf;

y = NaN(length(t),length(x0));
y(1,:) = x0;
for tInd = 1:length(t)-1
    dydt = dxdt(t(tInd),y(tInd,:)',params);
    y(tInd+1,:) = y(tInd,:) + dydt'*dt;
end
end