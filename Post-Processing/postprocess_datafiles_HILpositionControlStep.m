%% Experiemntal set up
t_step = 1; % [s] time duty is changed from zero to the trail value

%% load data
t = out.pos.Time;
pos = out.pos.Data;
duty = out.pump1Duty.Data+out.pump2Duty.Data;

it_step = find(t >= t_step,1,"first");
fs = 1/(t(2)-t(1));

%% Analyze step response
% Filter the position data to reduce noise using filtfilt()
 % Design a low-pass Butterworth filter
fc = 5; % Define the cut-off frequency
[b, a] = butter(2, fc/(fs/2)); % Design a 6th-order Butterworth filter
% freqz(b,a,[],fs)
filtered_pos = filtfilt(b, a, pos); % Apply zero-phase filtering

% Calculate the velocity from position data
velocity = gradient(filtered_pos, t); % [m/s] compute the velocity

% Use Kalman filter

[x_est, P_trace] = kalmanFilter(t,pos,duty);

kalman_pos = x_est(1,:);
kalman_vel = x_est(2,:);


% Find the terminal velocity before it drops to zero
% terminal_velocity = max(velocity(velocity > 0)); % maximum positive velocity


%% plotting

switch 1
    case 1
figure('Units', 'Inches', 'Position', [1, 1, 7, 5], 'PaperSize', [7, 5])
sgtitle('PWM Duty to Velocity Step Response Analysis with State Estimation', 'FontName', 'Times', 'FontSize', 14) % Add title to the figure

subplot(2,1,1)
plot(t,pos*100,"Color",[0.5,0.5,0.5],'LineWidth',0.2)
hold on
plot(t,filtered_pos*100,"Color",'r','LineWidth',1)
plot(t,kalman_pos*100,"Color",'b','LineWidth',1)
set(gca,'FontSize',10,'FontName','times')
ylabel('position (cm)', 'FontName', 'Times', 'FontSize', 10)
xlabel('time (s)', 'FontName', 'Times', 'FontSize', 10)
xlim([0.5 3])
legend('measured','Butterworth filtered (filtfilt)','Kalman filtered', 'FontName', 'Times', 'FontSize', 9)
grid on

subplot(2,1,2)
plot(t,velocity*100,'Color','r','LineWidth',1)
hold on
plot(t,kalman_vel*100,'b','LineWidth',1)
set(gca,'FontSize',10,'FontName','times')
ylabel('velocity (cm/s)', 'FontName', 'Times', 'FontSize', 12)
xlabel('time (s)', 'FontName', 'Times', 'FontSize', 12)
xlim([0.5 3])
legend('derived from Butterworth result','Kalman filter', 'FontName', 'Times', 'FontSize', 9)
grid on

    case 2
subplot(2,1,2)
hold on
plot(t,velocity*100)
% plot(t,kalman_vel*100,'k')
set(gca,'FontSize',10,'FontName','times')
ylabel('velocity (cm/s)', 'FontName', 'Times', 'FontSize', 10)
xlabel('time (s)', 'FontName', 'Times', 'FontSize', 10)
grid on
end

%%
figure('Units', 'Inches', 'Position', [1, 1, 2, 1.5], 'PaperSize', [8, 6])
plot(t,pos*100,"Color",[0.5,0.5,0.5],'LineWidth',0.2)
hold on
plot(t,filtered_pos*100,"Color",'r','LineWidth',1)
plot(t,kalman_pos*100,"Color",'b','LineWidth',1)
set(gca,'FontSize',10,'FontName','times')
% ylabel('position (cm)', 'FontName', 'Times', 'FontSize', 12)
% xlabel('time (s)', 'FontName', 'Times', 'FontSize', 12)
xlim([0.9 1.5])
grid on