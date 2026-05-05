close all, clear
% Define Accumualtor Parameters
V_total = 20 / 264.172; % m^3
P_pre = 500 * 6894.757; % Pa
P0 = 10e6; % Pa
n = 1; % Polytropic index
rho = 1000;
nu = 30e-6; % m^2/s

% Line diameter
D = .75 * .0254; % m^2
A = pi*D^2/4;
L = 3;

% Calculate fluid volume to have the initial pressure P0
    % P1 V1^n = P2 V2^n
    % V1 and V2 are air volumes (Vfluid + Vair = Vtotal)
V0 = V_total - (V_total^n*P_pre/P0)^(1/n);

% Define valve constant
k = (6.5*A)/sqrt(10e6);
Cd = .8;
A_oriface = k/Cd*sqrt(rho/2);
D_oriface = sqrt(4*A_oriface/pi)/.0254

%%
tf = 100; dt = .1;
t = 0:dt:tf;

% Initialize vectors
V = NaN(size(t)); V(1) = V0;
P = NaN(size(t));
Q = NaN(size(t));

% Loop over time
for tInd = 1:length(t)-1
    P(tInd) = P_pre*(V_total/(V_total-V(tInd)))^n;
    Q(tInd) = k*sqrt(P(tInd));
    V(tInd+1) = V(tInd) - Q(tInd)*dt; 
end
P(end) = P_pre*(V_total/(V_total-V(end)))^n;
Q(end) = k*sqrt(P(end));

% Find discharge time
[~,tInd_discharge] = min(abs(V));
t(tInd_discharge)

% Plot results
% figure, plot(t,P)
% figure, plot(t,V)


%% Friction factor
% Find fluid velocity
V = max(Q)/A;

% Calculate reynolds number
Re = V*D/nu

% Read friction factor from moody diagram
    % Conservative estimate: Overpredict delP by over estimating the ff
ff = .05;

% Find the pressure drop in the pipes in psi
delP = ff * L/D*rho*V^2/2 / 6894.757