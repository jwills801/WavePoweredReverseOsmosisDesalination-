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
% maximum power level for the device. Powers above the selected rated power
% will only generate the rated power. We can quantify the reduction in
% total yearly average power for each selected rated power. 

% Also, the speed of the stepped piston shaft is roughly proportional to
% the power.


% FILE DEPENDENCY:
% data_coulombPTO_dampingStudy_20220927_slim.mat
%
% UPDATES:
% 03/25/2026 - Created.

%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
clear, close all
% Load power data
load('data_coulombPTO_dampingStudy_20220927_slim.mat')

% Find peak power at each sea condition
avePowOpt = NaN(size(weight));
torqueOpt = NaN(size(weight));
for i = 1:length(Hs)
    [avePowOpt(i),torqueIndOpt] = max(PP_w_data(i,:));
    torqueOpt(i) = T_c_data(i,torqueIndOpt);
end

% Calculate Contribution to Annual Average Power
avePowContribution = avePowOpt.*weight/100; % Divide by 100 because the weights are percentages

% Successivly cut off powers
powCutOff = linspace(0,max(avePowOpt),100);
TotalAvePow = NaN(size(powCutOff));
for j = 1:length(powCutOff)
    tmp = avePowOpt;
    tmp( avePowOpt>powCutOff(j) ) = powCutOff(j);
    TotalAvePow(j)= sum(tmp.*weight/100);
end

%% Plots

% Power cutoff plots
figure, plot(powCutOff/1e3,TotalAvePow/1e3), grid
xlabel('Power Cutoff [kW]')
ylabel('Annual Power Power [kW]')
fileNameString = 'PowerCutoff';
saveas(gcf,['figures/pngs/', fileNameString,'.png'])
saveas(gcf,['figures/figs/', fileNameString,'.fig'])

figure, plot(powCutOff/1e3,(max(TotalAvePow)-TotalAvePow)/1e3), grid
xlabel('Power Cutoff [kW]')
ylabel('Loss in Annual Power Power [kW]')
fileNameString = 'LossFromPowerCutoff';
saveas(gcf,['figures/pngs/', fileNameString,'.png'])
saveas(gcf,['figures/figs/', fileNameString,'.fig'])


% Joint probabilities
plotJointProb = makeHeatMap(Tp,Hs,weight,'Peak Period [s]','Significant Wave Height [m]','Joint Probability');
saveas(plotJointProb,'Barchart.png')


% Optimal Powers
plotOptPow = makeHeatMap(Tp,Hs,avePowOpt/1e6,'Peak Period [s]','Significant Wave Height [m]','Average Power [MW]');

% Optimal Torques
plotOptTorque = makeHeatMap(Tp,Hs,torqueOpt/1e6,'Peak Period [s]','Significant Wave Height [m]','Best PTO Torque [MNm]');

% Optimal Torques
plotPowContribution = makeHeatMap(Tp,Hs,avePowContribution/1e3,'Peak Period [s]','Significant Wave Height [m]','Contribution to Annual Average Power [kW]');

function h = makeHeatMap(x,y,z,x_name,y_name,z_name)
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
saveas(h,['figures/pngs/', fileNameString,'.png'])
saveas(h,['figures/figs/', fileNameString,'.fig'])
end