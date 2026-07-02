function traj = makeDesiredTrajectory(ft)
%% Construct time vector
t = 0:.1:ft;

% inputType 'sine';
%type = 'steps';
        % sin
        amplitude = .1;
        period = 10;
        omega = 2*pi/period;
        xdes = amplitude*sin(omega*t);
        xdotdes = omega*amplitude*cos(omega*t);

% switch inputType
%     case 'sine'
%         % sin
%         amplitude = .1;
%         period = 10;
%         omega = 2*pi/period;
%         xdes = amplitude*sin(omega*t);
%         xdotdes = omega*amplitude*cos(omega*t);
% 
%     case 'steps'
%         stepTimes = [18.6, 28.3, 37.3, 46, 54.1, 61.2, 69.6, 78.2, 85.1, 90.5, 95.4, ft];
%         stepValues = [-5 5 -5 4 -4 3 -3 2 -2 1 -1 0 0]/100;
% 
%         xdes = NaN(size(t));
%         [~,ind1] = min(abs(t-stepTimes(1)));
%         xdes(1:(ind1-1)) = stepValues(1);
%         for i = 1:length(stepTimes)-1
%             [~,ind1] = min(abs(t-stepTimes(i)));
%             [~,ind2] = min(abs(t-stepTimes(i+1)));
% 
%             xdes(ind1:(ind2-1)) = stepValues(i+1);
%         end
%         xdotdes = zeros(size(t));
% end

%% Output trajectory
traj.time = t;
traj.xdes = xdes;
traj.xdotdes = xdotdes;


end