load('negTest_0_-36.mat')

figure
plot(out.pos.Time, 1e2*out.pos.data)

xlabel('time (s)')
ylabel('position (cm)')