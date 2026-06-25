load ../Data_20260624.mat
time = out.p_AC.Time;
P_cap = out.p_AC.Data;
P_rod = out.p_BD.Data;
x = out.x_wp.Data;
xdot = [0;diff(x)./diff(time)];


traj = makeDesiredTrajectory(ft);
figure
subplot(311), plot(time,x,traj.time,traj.xdes), grid, ylabel('Pos [m]')
subplot(312), plot(time,xdot), grid, ylabel('Vel [m/s]')
subplot(313), plot(time,P_cap/1e6,time,P_rod/1e6), grid, legend('Cap','Rod'), ylabel('Pressure [MPa]')
