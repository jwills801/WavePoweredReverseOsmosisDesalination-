d_bore_act = (6)*0.0254; % [in -> m]
d_rod_act = (3)*0.0254; % [in -> m]
A_cap = pi/4*d_bore_act^2;
A_rod = pi/4*(d_bore_act^2 - d_rod_act^2);

m = 8000 * A_rod*2; % [kg] mass of both pistons (rho * pi r^2 * L)
c = 1e3; % [Ns/m]
beta = 1.8e9;
V_cap = A_cap*0.5;
V_rod = A_rod*0.5;
D = 53 * 100^-3; % [m^3/rev]
omega = 2500 /60; % [rev/s]

tau = .1; % time constant of swash plate
ku = 1;

A = [0 1 0 0 0;
     0 -c/m A_cap/m -A_rod/m 0;
     0 -beta/V_cap*A_cap 0 0 -beta/V_cap*D*omega;
     0 beta/V_rod*A_rod 0 0 beta/V_rod*D*omega;
     0 0 0 0 -1/tau];
B = [0;0;0;0;ku/tau];
Bd = [0;-1/m;0;0;0];


poles = eig(A);
% figure, plot(real(poles),imag(poles),'*')

params.A = A;
params.B = B;
tf = 10;
dt = .01;
params.t = 0:dt:tf;
params.xdes = 0*params.t +.5;
params.xdotdes = 0*params.t;
params.Ki = -5;
params.Kp = -1;
x0 = [0 0 0 0 0];

[t,y] = ode23(@(t,y) func(t,y,params),[0 tf],x0);

close all
figure
subplot(221), plot(t,y(:,1),params.t,params.xdes), grid, legend('Actual','Desired')
subplot(222), plot(t,y(:,2),params.t,params.xdotdes), grid, legend('Actual','Desired')
subplot(223), plot(t,y(:,3:4)), grid, legend('Cap','Rod')
subplot(224), plot(t,y(:,5))
function dxdt = func(t,x,params)

    xdes = interp1(params.t,params.xdes,t);
    xdotdes = interp1(params.t,params.xdotdes,t);
    
    x_desired = [xdes; xdotdes; 0; 0; 0];
    e = x_desired - x; 

    u = params.Ki*e(1) + params.Kp*e(2);
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