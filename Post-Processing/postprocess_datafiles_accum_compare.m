clear

%% Collect data from data files
dpdt_ub = 70e3; % [Pa/s] upper limit to rate of change in pressure
maxOr97 = 1;
SS = 2; % Sea State to analyze
fileName_wActiveRV = ['data_refPTO_accum_wActiveRV_20230714_',num2str(SS),'_all.mat'];
fileName_wPassiveRV = ['data_refPTO_accum_wPassiveRV_20230712_',num2str(SS),'_all.mat'];
fileName_woRV = ['data_refPTO_accum_woRV_20230713_',num2str(SS),'_all.mat'];

% add data and utilities folders from the path
dataFolders = genpath('Data');
addpath(dataFolders)
addpath('Utilities')

% load and analyze case without RV
load(fileName_woRV,'Vtotal','dpdt_max_array','dpdt_97_array')
switch maxOr97
  case 1
    dpdt_metric = dpdt_max_array;
  case 2
    dpdt_metric = dpdt_97_array;
end
i_woRV = find(dpdt_metric <= dpdt_ub,1,'first');
Vtotal_woRV = Vtotal(i_woRV);
clearvars dpdt_metric dpdt_max_array dpdt_97_array Vtotal i_woRV 


% load and analyze case with passive RV
load(fileName_wPassiveRV,'Vtotal_mesh','X_mesh','kv_mesh',...
    'dpdt_max_array','dpdt_97_array','PP_rv_array','PP_WEC_array')
switch maxOr97
  case 1
    dpdt_metric = dpdt_max_array;
  case 2
    dpdt_metric = dpdt_97_array;
end
PP_metric = 100*PP_rv_array./PP_WEC_array;
 % find individuals meeting dpdt criterion
[~,meetsConstraints] = find(dpdt_metric <= dpdt_ub);
 % find non-dominated individuals from set meeting dpdt criterion
non_dominated = paretoFront2D(Vtotal_mesh(meetsConstraints),'min', ...
                              PP_metric(meetsConstraints),'min');
[~, ii_sort] = sort(Vtotal_mesh(meetsConstraints(non_dominated)));
ii = meetsConstraints(non_dominated(ii_sort));
Vtotal_wPassiveRV = Vtotal_mesh(ii);
PP_metric_wPassiveRV = PP_metric(ii);
X_wPassiveRV = X_mesh(ii);
kv_wPassiveRV = kv_mesh(ii);
clearvars dpdt_metric dpdt_max_array dpdt_97_array ...
    Vtotal_mesh X_mesh kv_mesh PP_rv_array ...
    meetsConstraints non_dominated ii

% load and analyze case with active RV
load(fileName_wActiveRV,'Vtotal_mesh','X_mesh','kv_mesh',...
    'dpdt_max_array','dpdt_97_array','PP_rv_array')
switch maxOr97
  case 1
    dpdt_metric = dpdt_max_array;
  case 2
    dpdt_metric = dpdt_97_array;
end
PP_metric = 100*PP_rv_array./PP_WEC_array;
 % find individuals meeting dpdt criterion
[~,meetsConstraints] = find(dpdt_metric <= dpdt_ub);
 % find non-dominated individuals from set meeting dpdt criterion
non_dominated = paretoFront2D(Vtotal_mesh(meetsConstraints),'min', ...
                              PP_metric(meetsConstraints),'min');
[~, ii_sort] = sort(Vtotal_mesh(meetsConstraints(non_dominated)));
ii = meetsConstraints(non_dominated(ii_sort));
Vtotal_wActiveRV = Vtotal_mesh(ii);
PP_metric_wActiveRV = PP_metric(ii);
X_wActiveRV = X_mesh(ii);
kv_wActiveRV = kv_mesh(ii);
clearvars dpdt_metric dpdt_max_array dpdt_97_array ...
    Vtotal_mesh X_mesh kv_mesh PP_rv_array PP_WEC_array PP_metric...
    meetsConstraints non_dominated ii

% remove data folders from the path
rmpath(dataFolders)

%% Plot power loss versus total accumulator volume for pareto optimal 
plotDesignVars = 1;

switch maxOr97
    case 1
        varLabel = 'Maximum';
    case 2
        varLabel = '97th Percentile';
end


black = [0 0 0];
maroon = [122 0 25]/256;
gold = [255 204 51]/256;
blue = [0 75 135]/256;
orange = [226 100 55]/256;
green = [63 150 87]/256;
color = [maroon; gold; blue; orange; green];
markerType = '.ox*^s';

bottomEdge = 1;
leftEdge = 3;
width = 7.5; % one column: 3+9/16, two column: 7.5
height = 2.5;
if plotDesignVars; height = 7.5; end
fontSize = 9;
lineWidth = 1;

clearvars leg

xlimAdd = 5;

fig = figure;
fig.Units = 'inches';
fig.Position = [leftEdge bottomEdge width height ];

n_plots = 1;
if plotDesignVars; n_plots = 3; end

% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
iax = 1;
ax(iax) = subplot(n_plots,1,iax);
ax(iax).FontName = 'times';
ax(iax).FontSize = fontSize-1;

i = 1;
p(iax,i) = semilogy(Vtotal_wPassiveRV,PP_metric_wPassiveRV);
p(iax,i).Color = black;
p(iax,i).Marker = markerType(i);
p(iax,i).MarkerSize = 5;
p(iax,i).LineWidth = 1.5;
hold on

i = 2;
p(iax,i) = semilogy(Vtotal_wActiveRV,PP_metric_wActiveRV);
p(iax,i).Color = maroon;
p(iax,i).Marker = markerType(i);
p(iax,i).MarkerSize = 5;
p(iax,i).LineWidth = 1.5;

yLim = ylim;
ylim([1e-1 yLim(2)])

i = 3;
try
p(iax,i) = plot([1 1]*Vtotal_woRV,[1e-1 yLim(2)],'--k');
p(iax,i).LineWidth = 1.5;
catch
end

grid on
xlabel('volume (1000L) ', ...
'Interpreter','latex','FontSize',fontSize-1,'fontname','Times')
ylabel('power loss (x100\%)', ...
'Interpreter','latex','FontSize',fontSize-1,'fontname','Times')

titleString = ['Power Loss Normalized to Mean Power Capture Versus Accumulator Volume',newline,...
            'with ',varLabel,' Rate of Pressure Change Limited to ',num2str(1e-3*dpdt_ub,2),' kPa/s',newline,...
            'Sea State ',num2str(SS)];
title(titleString,...
'Interpreter','latex','FontSize',fontSize,'fontname','Times')

leg = legend('passive valve','active valve','no valve');
leg.FontSize = fontSize-1;
leg.FontName = 'Times';
% rect = [0.5, -0.2, 0.25, 0.15];
% set(leg, 'Position', rect)
set(leg, 'Location', 'best')
xLim = xlim;
xlim([0 xLim(2)+xlimAdd])

if ~plotDesignVars; return; end

% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% distribution of accumulators versus total volume
iax = 2;
ax(iax) = subplot(n_plots,1,iax);
ax(iax).FontName = 'times';
ax(iax).FontSize = fontSize-1;

i = 1;
p(iax,i) = plot(Vtotal_wPassiveRV,X_wPassiveRV);
p(iax,i).Color = black;
p(iax,i).Marker = markerType(i);
p(iax,i).MarkerSize = 5;
p(iax,i).LineWidth = 1.5;
hold on

i = 2;
p(iax,i) = plot(Vtotal_wActiveRV,X_wActiveRV);
p(iax,i).Color = maroon;
p(iax,i).Marker = markerType(i);
p(iax,i).MarkerSize = 5;
p(iax,i).LineWidth = 1.5;

grid on
xlabel('volume (1000L) ', ...
'Interpreter','latex','FontSize',fontSize-1,'fontname','Times')
ylabel('portion of volume at RO inlet (x100\%)', ...
'Interpreter','latex','FontSize',fontSize-1,'fontname','Times')
xLim = xlim;
xlim([0 xLim(2)+xlimAdd])
yLim = ylim;
ylim([0 yLim(2)])

title("Distribution of Accumulator Volume",...
'Interpreter','latex','FontSize',fontSize,'fontname','Times')

% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% distribution of accumulators versus total volume
iax = 3;
ax(iax) = subplot(n_plots,1,iax);
ax(iax).FontName = 'times';
ax(iax).FontSize = fontSize-1;

i = 1;
p(iax,i) = plot(Vtotal_wPassiveRV,kv_wPassiveRV*1000*sqrt(1000));
p(iax,i).Color = black;
p(iax,i).Marker = markerType(i);
p(iax,i).MarkerSize = 5;
p(iax,i).LineWidth = 1.5;
hold on

i = 2;
p(iax,i) = plot(Vtotal_wActiveRV,kv_wActiveRV*1000*sqrt(1000));
p(iax,i).Color = maroon;
p(iax,i).Marker = markerType(i);
p(iax,i).MarkerSize = 5;
p(iax,i).LineWidth = 1.5;

grid on
xlabel('volume (1000L) ', ...
'Interpreter','latex','FontSize',fontSize-1,'fontname','Times')
ylabel('valve coefficient (L/s/kPa^{1/2}))', ...
'Interpreter','latex','FontSize',fontSize-1,'fontname','Times')
xLim = xlim;
xlim([0 xLim(2)+xlimAdd])
yLim = ylim;
ylim([0 yLim(2)])

title("Valve Specification",...
'Interpreter','latex','FontSize',fontSize,'fontname','Times')