% Size_Power.m script m-file
% AUTHORS:
% Jackson Wills (email: wills224@umn.edu)
% University of Minnesota
% Department of Mechanical Engineering
%
% CREATION DATE:
% 03/25/2026
%
% PURPOSE/DESCRIPTION:
% This script analyzes data from
% data_coulombPTO_dampingStudy_20220927_slim.mat, which was made by Jeremy
% simmons in his 2021-TimeAvePTOarchectureStudy project on his drive folder
% in the (MEPS) Wave Energy Harvest drive.
%
% This script looks at the max power (and corresponding torque) at a
% variety of sea states. It also uses a Joint probability of occurrence
% (percent) for sea conditions from a reference site near Humboldt Bay,
% California from a paper titled Analysis of a wave-powered,
% reverse-osmosis system and its economic availability in the United States
% by Yu and Jenne.

% By combining the power and the joint probability, we can calculate the
% contribution of each sea states average power to the cummulative average
% power of the device over the entire year. We would then like to pick a
% maximum torque and speed for the device. Powers above the selected torque
% or speed will generate less power. We can quantify the reduction in
% total yearly average power for each selected rated power. 


% FILE DEPENDENCY:
% data_coulombPTO_dampingStudy_20220927_slim.mat
%
% UPDATES:
% 03/25/2026 - Created, looked at max power
% 04/08/2026 - changed to look at max speeds and torque
% 04/16/2026 - Adjusted saturated operating conditions

%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
clear, close all

saveFigs = 0;

% Load power data
load('data_coulombPTO_dampingStudy_20220927_slim.mat')

% Find peak power at each sea condition
avePowOpt = NaN(size(weight));
torqueOpt = NaN(size(weight));
for cutInd = 1:length(Hs)
    [avePowOpt(cutInd),torqueIndOpt] = max(PP_w_data(cutInd,:));
    torqueOpt(cutInd) = T_c_data(cutInd,torqueIndOpt);
end

% Calculate Contribution to Annual Average Power
avePowContribution = avePowOpt.*weight/100; % Divide by 100 because the weights are percentages

% Find average speed - this is a proxy for the amount of flow that the
% stepped piston must remove from the accumulators
aveSpeed = avePowOpt./torqueOpt;

%% Successively cut off speeds and torques
% Define Cut off speeds
nS = 10;
maxSpeeds = linspace(min(aveSpeed(:)),max(aveSpeed(:)),nS);

% Define Cut off torques
nT = 10;
maxTorques = linspace(min(torqueOpt(:)),max(torqueOpt(:)),nT);

% Create a grid of max speeds and torques
[S,T] = ndgrid(maxSpeeds,maxTorques);

% inialize
TotalAvePow = NaN(size(S));

% Loop over grid values of max speeds and torques
for cutInd = 1:nS*nT
    % Max speeds and torques
    maxSpeed = S(cutInd);
    maxTorque = T(cutInd);

    % initialize 
    powCut = NaN(size(weight));
    for seaInd = 1:length(weight)
        % Get grid search data
        powerData = PP_w_data(seaInd,:);
        torqueData = T_c_data(seaInd,:);

        % Get operating conditions for this sea state
        [powCut(seaInd),torCut,speCut] = cutTorque_and_Speed(powerData,torqueData,maxSpeed,maxTorque);     
    end

    % Calculate Contribution to Annual Average Power
    TotalAvePow(cutInd) = sum(powCut .*weight/100); % Divide by 100 because the weights are percentages
end

%% Cut off at a specific speed and torque
maxSpeed = 1 /60*2*pi; % 1 RPM converted to rad/s
maxTorque = 3e6;

% Initilize vectors
powerCutOff = NaN(size(weight));
torqueCutOff = NaN(size(weight));
speedCutOff = NaN(size(weight));

% Loop over sea states
    for seaInd = 1:length(weight)
        % Get grid search data
        powerData = PP_w_data(seaInd,:);
        torqueData = T_c_data(seaInd,:);

        % Get operating conditions for this sea state
        [powerCutOff(seaInd),torqueCutOff(seaInd),speedCutOff(seaInd)] = cutTorque_and_Speed(powerData,torqueData,maxSpeed,maxTorque);     
    end
totalAvePowCut = sum(powerCutOff .*weight/100); % Divide by 100 because the weights are percentages

% Save data for Sayak
% save('cutoffTorque_and_Speed.mat','Tp','Hs','speedCutOff',"torqueCutOff","powerCutOff")

%% Plots

% Power cutoff plots
levels = [50 100 150 200 250, (.99*max(TotalAvePow(:)/1e3)), totalAvePowCut/1e3];
figure, contour(S*60/2/pi,T/1e6,TotalAvePow/1e3,levels,'ShowText','on',"LabelFormat","%1.f kW")
hold on, plot([min(S(:)), max(S(:))]*60/2/pi,[maxTorque,maxTorque]/1e6,'k--')
plot([maxSpeed,maxSpeed]*60/2/pi,[min(T(:)), max(T(:))]/1e6,'k--')
%scatter(maxSpeed*60/2/pi,maxTorque/1e6,500,"r.")
% annotation('textbox',[.5 .175 .3 .3],'String',['Annual Average Power: ', num2str(totalAvePowCut/1e3,'%1.f'),' kW'],'FitBoxToText','on','Color', 'red','EdgeColor', 'none');
xlabel('Max Speed [RPM]')
ylabel('Max Torque [MNm]')
fileNameString = 'Torque_and_SpeedCutoff';
if saveFigs
    saveas(gcf,['figures/figs/', fileNameString,'.fig'])
    exportgraphics(gcf, ['figures/pngs/', fileNameString,'.png']);
end
%%
% Joint probabilities
plotJointProb = makeHeatMap(Tp,Hs,weight,'Peak Period [s]','Significant Wave Height [m]','Joint Probability',saveFigs);

% Optimal Powers
plotOptPow = makeHeatMap(Tp,Hs,avePowOpt/1e3,'Peak Period [s]','Significant Wave Height [m]','Unstaturated Average Power [kW]',saveFigs);

% Optimal Torques
plotOptTorque = makeHeatMap(Tp,Hs,torqueOpt/1e6,'Peak Period [s]','Significant Wave Height [m]','Unstaturated Best PTO Torque [MNm]',saveFigs);

% Annual Power Contribution
plotPowContribution = makeHeatMap(Tp,Hs,avePowContribution/1e3,'Peak Period [s]','Significant Wave Height [m]','Unstaturated Contribution to Annual Average Power [kW]',saveFigs);

% Cutoff Speeds
plotCutOffSpeed = makeHeatMap(Tp,Hs,speedCutOff*60/2/pi,'Peak Period [s]','Significant Wave Height [m]',['Average Speed (RPM) after ',num2str(maxSpeed*60/2/pi),'RPM Cutoff '],saveFigs);

% Cutoff Torques
plotCutOffTorque = makeHeatMap(Tp,Hs,torqueCutOff/1e6,'Peak Period [s]','Significant Wave Height [m]',['PTO Torque (MNm) after ',num2str(maxTorque/1e6),'MNm Cutoff'],saveFigs);

% Cutoff Powers
plotCutOffPow = makeHeatMap(Tp,Hs,powerCutOff/1e3,'Peak Period [s]','Significant Wave Height [m]',['Average Power (kW) after ',num2str(maxSpeed*60/2/pi),'RPM and ',num2str(maxTorque/1e6),'MNm Cutoff '],saveFigs);

function h = makeHeatMap(x,y,z,x_name,y_name,z_name,saveFigs)
figure

% Make table
tbl = table(x(:), y(:), z(:));

% make heatmap
h = heatmap(tbl, 'Var1', 'Var2', 'ColorVariable', 'Var3');

h.XLabel = x_name;
h.YLabel = y_name;
h.Title = z_name;

% Set NaN cells to white
h.MissingDataColor = [1 1 1];

% Set cell labels to 1 significant figure
h.CellLabelFormat = '%.1f';

% Remove spaces and units for filenames
fileNameString = z_name(~isspace(z_name));
fileNameString(find(fileNameString=='['):end)='';

% Save figures
if saveFigs
    saveas(h,['figures/figs/', fileNameString,'.fig'])
    exportgraphics(h, ['figures/pngs/', fileNameString,'.png']);
end

end


function [powCut,torCut,speCut] = cutTorque_and_Speed(powerData,torqueData,maxSpeed,maxTorque)
% powerData and torqueData are vectors at a specific sea state showing the
% relationship between control torque and absorbed power.
% If we cut off the speed and torque, what will the power be?
powerData4Plot = powerData;

% Calculate speed
speedData = powerData./torqueData;

% Disallow over torquing and over speeding
allowedInds = torqueData<maxTorque & speedData<maxSpeed;
powerData(~allowedInds) = 0;

% Calculate the effective power under constraints
if sum(allowedInds) == 0 % if none of the torques meet the contraint
    % This is an overpowered seastate. Use the max speed and max
    % torque and the rest will go over relief
    powCut = maxSpeed * maxTorque;
    torCut = maxTorque;
    speCut = maxSpeed;
else % choose the max power within these constraints
    [powCut,cutInd] = max(powerData);
    torCut = torqueData(cutInd);
    speCut = speedData(cutInd);
end

% You can click through these plots if you want to
if 0
    figure, plot(torqueData,powerData4Plot,[maxTorque,maxTorque],[min(powerData4Plot), max(powerData4Plot)],torqueData,maxSpeed*torqueData,torCut,powCut,'*')
    ylim([min(powerData4Plot), max(powerData4Plot)])
    xlabel('Torque [Nm]'), ylabel('Power [W]'), grid
    a=1;
end

end