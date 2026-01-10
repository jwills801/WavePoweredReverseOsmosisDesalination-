function [x_est, P_trace] = kalmanFilter(t,z,u)
dt = t(2)-t(1);

% Define system model parameters
tau_v = 0.05;
tau_s = 0.05;

d_bore_act = (6)*0.0254; % [in -> m]
d_rod_act = (3)*0.0254; % [in -> m]
A_cap = pi/4*d_bore_act^2;
A_rod = pi/4*(d_bore_act^2 - d_rod_act^2);

k_v_fwd = 1/A_cap; % [m^2] area of piston (flow -> velocity)
k_v_rev = 1/A_rod; % [m^2] area of piston (flow -> velocity)
k_i = maxFLow(1800,1,53.8); % [m^3/s] flow rate at full displacement

% Noise parameters
R = 0.05^2; % Measurement noise variance
Q_c = diag([0, 0.1^2, 0.01^2]); % Process noise parameters

% Continuous time domain model
A_c_fwd = [0, 1, 0;
       0, -1/tau_v, k_v_fwd/tau_v;
       0, 0, -1/tau_s]; % State transition matrix
A_c_rev = [0, 1, 0;
       0, -1/tau_v, k_v_rev/tau_v;
       0, 0, -1/tau_s]; % State transition matrix
B_c = [0; 0; k_i/tau_s];

H = [1, 0, 0]; % Measure position only

% Pre-compute constant matrices
[F_fwd, Q_discrete_fwd, B_discrete] = van_loan_discretization(A_c_fwd, Q_c, B_c, dt);
[F_rev, Q_discrete_rev, ~] = van_loan_discretization(A_c_rev, Q_c, B_c, dt);

% Initialize state estimate and error covariance
x_est = zeros(numel(B_c),numel(t));
P_est = eye(numel(B_c)); % Initial error covariance matrix

% Kalman filter implementation
for it = 1:numel(t)
    % map control input to model (u - duty)
    fdisp = duty2f(u(it));


    % Prediction step
    if x_est(2,max(1,it-1)) >=0
        F = F_fwd;
        Q_discrete = Q_discrete_fwd;
    else
        F = F_rev;
        Q_discrete = Q_discrete_rev;
    end

    x_pred = F * x_est(:,max(1,it-1)) + B_discrete * fdisp;
    P_pred = F * P_est * F' + Q_discrete;

    % Update step
    S = H * P_pred * H' + R;           % Innovation covariance
    K = P_pred * H' / S;               % Kalman gain
    y = z(it) - H * x_pred;                % Innovation
    
    P_est = (eye(3) - K * H) * P_pred; % Covariance update
    P_trace(it) = trace(P_est);

    x_est(:,it) = x_pred + K * y;      % State update
    
end
end

function f  = duty2f(duty)
    posCutIn = 0.23;
    negCutIn = 0.23;
    
    f = ((duty-posCutIn)/(1-posCutIn))*(duty>posCutIn) + ...
        ((duty+negCutIn)/(1-negCutIn))*(duty<-negCutIn);
    f = max(-1,min(1,f));
end

function maxFlow_m3perSec = maxFLow(speed_rpm,numPumps,disp_ccPerRev)
    eff_vol = 0.92;
    displacement = disp_ccPerRev*(0.01)^3; % [cc/rev -> m^3/rev]
    maxFlow_m3perSec = numPumps*eff_vol*speed_rpm/60*displacement;
end