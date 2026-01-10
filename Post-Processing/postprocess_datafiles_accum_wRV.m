%% Collect data from data files
files = dir;
nfiles = size(files,1);
for j = 1:nfiles
display(['file ',num2str(j),' of ',num2str(nfiles)])
    if strfind(files(j).name,"data_refPTO_accum")
        load(files(j).name,'-regexp','^(?!out)\w')

        q_permMean_array(iVar) = q_permMean;
        PP_WEC_array(iVar) = PP_WEC;
        PP_wp_array(iVar) = PP_wp;
        PP_rv_array(iVar) = PP_rv;
        PP_hPRV_array(iVar) = PP_hPRV;
        PP_roPRV_array(iVar) = PP_roPRV;
        dpdt_max_array(iVar) = dpdt_max;
        dpdt_97_array(iVar) = dpdt_97;

    end

end

%% Find indices for missing data files

files = dir;
nfiles = size(files,1);
Done = [];
notDone = 1:nVar;
for j = 1:nfiles
display(['file ',num2str(j),' of ',num2str(nfiles)])
    if strfind(files(j).name,"data_refPTO_accum")
        load(files(j).name,'iVar')
        [r,c,val] = find(notDone==iVar);
        notDone = [notDone(1:c-1), notDone(c+1:end)];
        Done = [Done, iVar];
        
    end

end

try 
    doneArrayStr = num2str(Done(1));
    for j = 2:length(Done)
        switch 1
            case 1 
                doneArrayStr = append(doneArrayStr,[',',num2str(Done(j))]);
            case 2
                doneArrayStr = append(doneArrayStr,[',',num2str(Done(j),['%0',floor(log10(nVar)),'.f'])]);
        end
    end
catch
    % just move on
end

try
    jobArrayStr = num2str(notDone(1));
    for j = 2:length(notDone)
        jobArrayStr = append(jobArrayStr,[',',num2str(notDone(j))]);
        
    end    
    
    if 1
    for j = 1:length(notDone)
        iVar = notDone(j);
        q_permMean_array(iVar) = nan;
        PP_WEC_array(iVar) = nan;
        PP_wp_array(iVar) = nan;
        PP_rv_array(iVar) = nan;
        PP_hPRV_array(iVar) = nan;
        PP_roPRV_array(iVar) = nan;
        dpdt_max_array(iVar) = nan;
        dpdt_97_array(iVar) = nan;
    
        Vtotal_missing(j) = Vtotal_mesh(iVar);
        X_missing(j) = X_mesh(iVar);
        kv_missing(j) = kv_mesh(iVar);
        
    end
    end

    % Display study variable values with missing data
    tbl = table(notDone',1e3*Vtotal_missing',X_missing',kv_missing','VariableNames', {'iVar', 'Total Volume (L)','portion at RO inlet', 'kv'});
    disp(tbl);

catch
    % just move on
end


%% Transform data to 3D variable mesh
I = length(kv);
J = length(Vtotal);
K = length(X);


test = 1;
for i = 1:I
    for j = 1:J
        for k = 1:K
            m = J*K*(i-1) + K*(j-1) + k;

            q_permMean_3D(i,j,k) = q_permMean;
            PP_WEC_3D(i,j,k) = PP_WEC_array(m);
            PP_wp_3D(i,j,k) = PP_wp_array(m);
            PP_rv_3D(i,j,k) = PP_rv_array(m);
            PP_hPRV_3D(i,j,k) = PP_hPRV_array(m);
            PP_roPRV_3D(i,j,k) = PP_roPRV_array(m);
            dpdt_max_3D(i,j,k) = dpdt_max_array(m);
            dpdt_97_3D(i,j,k) = dpdt_97_array(m);

            Vtotal_3D(i,j,k) = Vtotal_mesh(m);
            X_3D(i,j,k) = X_mesh(m);
            kv_3D(i,j,k) = kv_mesh(m);
            test = (Vtotal_mesh(m) == Vtotal(j)) ...
                && (X_mesh(m) == X(k)) ...
                && (kv_mesh(m) == kv(i)) ...
                && test;
        end
    end
end

if ~test; error('indexing incorrect'); end
clearvars test


%% Plot average power loss from the ripple control valve as a function of total accumulator volume for distribution (color) and valve coefficient (line type)
 % select indices to plot
plotCase = 1;
switch plotCase
 case 1
     iiK = 3:1:K-2; % distribution
     iiI = 2:1:I;   % valve coeff.
 case 2
     iiK = 1:1:K;
     iiI = 4;
 case 3
     iiK = 3;
     iiI = 2:I;
end
nK = length(iiK);
nI = length(iiI);
   
 % select variable to plot
switch 1
  case 1
    YaxisVar = 100*PP_rv_3D./PP_WEC_3D;
    varStr = 'Ripple Control Valve Losses';
  case 2
    YaxisVar = 100*(PP_roPRV_3D + PP_hPRV_3D)./PP_WEC_3D;
    varStr = 'PRV Losses';
end

black = [0 0 0];
maroon = [122 0 25]/256;
gold = [255 204 51]/256;
blue = [0 75 135]/256;
orange = [226 100 55]/256;
green = [63 150 87]/256;
pink = [255 192 203]/256;
blue1 = [0 150 255]/256;
purple = [128 0 128]/256;
green1 = [0 255 150]/256;
color = [maroon; gold; blue; orange; green; pink; blue1; purple; green1];

linestyles = {'-', '--', '-.', ':','-', '--', '-.', ':',};

bottomEdge = 1;
leftEdge = 3;
width = 7.5; % one column: 3+9/16, two column: 7.5
height = 3.25;
fontSize = 9;
lineWidth = 1;

clearvars leg

fig = figure;
fig.Units = 'inches';
fig.Position = [leftEdge bottomEdge width height ];

n_plots = 1;
ax1 = subplot(n_plots,1,1);
ax1.FontName = 'times';
ax1.FontSize = fontSize-1;

hold on

% dummy plots for legend
iLeg = 0;

 % color - total volume
for k = 1:nK
    scatter(-99*[1, 0.5],-99*[1, 0.5],50, ...
        'filled','s','LineWidth',2,...
        'MarkerEdgeColor',color(k,:),'MarkerFaceColor',color(k,:));
    iLeg = iLeg+1;
    legLabels(iLeg) = convertCharsToStrings( ...
        ['fraction at RO inlet = ',num2str(X(iiK(k)))]);
end

for i = 1:nI
    plot(-99*[1, 0.5],-99*[1, 0.5],'k','LineStyle', linestyles{i});
    iLeg = iLeg+1;
    legLabels(iLeg) = convertCharsToStrings( ...
        ['k_v = ',num2str(kv(iiI(i))*1000*sqrt(1000),2),'(L/s/kPa^{1/2})']);
end

% plot real data

for k = 1:nK
    for i = 1:nI
        p(k,i) = plot(Vtotal,YaxisVar(iiI(i),:,iiK(k)), ...
            'LineStyle', linestyles{i}, ...
            'Color',color(k,:), ...
            'LineWidth',1);
        p(k,i).HandleVisibility='off';
    end
end

xlabel('volume (1000L) ', ...
'Interpreter','latex','FontSize',fontSize-1,'fontname','Times')
ylabel('power loss (x100\%)', ...
'Interpreter','latex','FontSize',fontSize-1,'fontname','Times')
switch par.ERUconfig.outlet
    case 1
        ERUstr = '';
    case 0
        ERUstr = 'and ERU Feed Outlet Downstream of Valve';
end
switch par.rvConfig.active
    case 0
        rvStr = 'Passive Ripple Control';
    case 1
        rvStr = 'Active Ripple Control';
end

titleString = ['Mean Power Loss Normalized to Mean Power Capture',newline...
                'With ',rvStr,ERUstr,': ',varStr,newline,...
                'Sea State ',num2str(SS)];
title(titleString,...
'Interpreter','latex','FontSize',fontSize,'fontname','Times')

leg = legend(legLabels);
leg.FontSize = fontSize-1;
leg.FontName = 'Times';
rect = [0.5, -0.2, 0.25, 0.15];
% set(leg, 'Position', rect)
set(leg, 'Location', 'best')
% set(leg, 'Location', 'southoutside')
xLim = xlim;
xlim([0 xLim(2)])
% ylim([0 1e-3*max(Y(:))])


%% Plot rate of change as a function of total accumulator volume for distribution (color) and valve coefficient (line type)
 % select indices to plot
plotCase = 1;
switch plotCase
 case 1
     iiK = 2:1:K-2; % distribution
     iiI = 3:1:I;   % valve coeff.
 case 2
     iiK = 1:1:K;
     iiI = 4;
 case 3
     iiK = 3;
     iiI = 2:I;
end
nK = length(iiK);
nI = length(iiI);
   
 % select variable to plot
maxOr97 = 1;
switch maxOr97
  case 1
    YaxisVar = dpdt_max_3D;
    varTitle = 'Maximum Rate of Change in Pressure';
  case 2
    YaxisVar = dpdt_97_3D;
    varTitle = '97th Percentile Rate of Change in Pressure';
end

black = [0 0 0];
maroon = [122 0 25]/256;
gold = [255 204 51]/256;
blue = [0 75 135]/256;
orange = [226 100 55]/256;
green = [63 150 87]/256;
pink = [255 192 203]/256;
blue1 = [0 150 255]/256;
purple = [128 0 128]/256;
green1 = [0 255 150]/256;
color = [maroon; gold; blue; orange; green; pink; blue1; purple; green1];

linestyles = {'-', '--', '-.', ':','-', '--', '-.', ':',};

bottomEdge = 1;
leftEdge = 3;
width = 7.5; % one column: 3+9/16, two column: 7.5
height = 3.25;
fontSize = 9;
lineWidth = 1;

clearvars leg

fig = figure;
fig.Units = 'inches';
fig.Position = [leftEdge bottomEdge width height ];

n_plots = 1;
ax1 = subplot(n_plots,1,1);
ax1.FontName = 'times';
ax1.FontSize = fontSize-1;

hold on

% dummy plots for legend
iLeg = 0;

 % color - total volume
for k = 1:nK
    scatter(-99*[1, 0.5],-99*[1, 0.5],50, ...
        'filled','s','LineWidth',2,...
        'MarkerEdgeColor',color(k,:),'MarkerFaceColor',color(k,:));
    iLeg = iLeg+1;
    legLabels(iLeg) = convertCharsToStrings( ...
        ['fraction at RO inlet = ',num2str(X(iiK(k)))]);
end

for i = 1:nI
    plot(-99*[1, 0.5],-99*[1, 0.5],'k','LineStyle', linestyles{i});
    iLeg = iLeg+1;
    legLabels(iLeg) = convertCharsToStrings( ...
        ['k_v = ',num2str(kv(iiI(i))*1000*sqrt(1000),2),'(L/s/kPa^{1/2})']);
end

% plot real data

for k = 1:nK
    for i = 1:nI
        p(k,i) = plot(Vtotal,1e-3*YaxisVar(iiI(i),:,iiK(k)), ...
            'LineStyle', linestyles{i}, ...
            'Color',color(k,:), ...
            'LineWidth',1);
        p(k,i).HandleVisibility='off';
    end
end

% plot target limit
iLeg = iLeg+1;
plot(Vtotal([1 end]),1e-3*par.control.dpdt_ROmax*[1 1],'--r')
legLabels(iLeg) = convertCharsToStrings( ...
        ['target limit']);

xlabel('volume (1000L) ', ...
'Interpreter','latex','FontSize',fontSize-1,'fontname','Times')
ylabel('rate of change in pressure (kPa/s)', ...
'Interpreter','latex','FontSize',fontSize-1,'fontname','Times')
switch par.ERUconfig.outlet
    case 1
        ERUstr = '';
    case 0
        ERUstr = 'and ERU Feed Outlet Downstream of Valve';
end
switch par.rvConfig.active
    case 0
        rvStr = 'Passive Ripple Control';
    case 1
        rvStr = 'Active Ripple Control';
end

titleString = [varTitle,' With ',rvStr,ERUstr,':',newline,...
                'Sea State ',num2str(SS)];
title(titleString,...
'Interpreter','latex','FontSize',fontSize,'fontname','Times')

leg = legend(legLabels);
leg.FontSize = fontSize-1;
leg.FontName = 'Times';
rect = [0.5, -0.2, 0.25, 0.15];
% set(leg, 'Position', rect)
set(leg, 'Location', 'best')
% set(leg, 'Location', 'southoutside')
xLim = xlim;
xlim([0 xLim(2)])
yLim = ylim;
ylim([0 yLim(2)])
% ylim([0 1e-3*1.5*par.control.dpdt_ROmax])

%% Plot power loss versus total accumulator volume for pareto optimal 
% designs meeting threshhold on rate of pressure change

XaxisVar = Vtotal_mesh';
YaxisVar = 100*PP_rv_array./PP_WEC_array;
bounds = [1.001 1 0.90 0.75 0.5 0];
N = numel(bounds)-1; % Number of bins with bounds
dpdt_ub = par.control.dpdt_ROmax*bounds;
maxOr97 = 1;
switch maxOr97
    case 1
        dpdt_metric = dpdt_max_array;
        varLegLabel = 'max';
        varLabel = 'Maximum';
    case 2
        dpdt_metric = dpdt_97_array;
        varLegLabel = '97';
        varLabel = '97th Percentile';
end



iDomStart = ones(1,N+1);
iDom = [];
% Loop through bounds
for k = 1:N
    % Find individuals meeting dpdt bounds
    ub = dpdt_ub(k);
    lb = dpdt_ub(k+1);
    [~,meetsConstraints] = find(dpdt_metric <= ub);

    % load objectives
    obj1 = -XaxisVar(meetsConstraints);
    obj2 = -YaxisVar(meetsConstraints);

    % Number of individuals
    n = numel(obj1);

    % Initialize dominance matrix
    dominance = false(n);
    
    % figure
    % scatter(obj1,obj2)
    % hold on
    % Find and mark dominating individuals meeting dpdt criterion
    for i = 1:n
        for j = 1:n
            if obj1(i) >= obj1(j) && obj2(i) >= obj2(j) ...
               && (obj1(i) > obj1(j) || obj2(i) > obj2(j))
                dominance(i,j) = true;
            end
        end
    end
    
    % Identify non-dominated individuals
    non_dominated = find(sum(dominance, 1) == 0)

    % scatter(obj1(non_dominated),obj2(non_dominated))

    % Sort non-dominated individuals based on objective values
    [~, sort_idx] = sort(-obj1(non_dominated));
    Ndom = numel(non_dominated);

    iDomStart(k+1) = iDomStart(k) + Ndom;
    iDom = [iDom meetsConstraints(non_dominated(sort_idx))];
end
iDomStart(k+1) = numel(iDom)+1;

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
height = 6;
fontSize = 9;
lineWidth = 1;

clearvars leg

fig = figure;
fig.Units = 'inches';
fig.Position = [leftEdge bottomEdge width height ];

n_plots = 3;

% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
iax = 1;
ax(iax) = subplot(n_plots,1,iax);
ax(iax).FontName = 'times';
ax(iax).FontSize = fontSize-1;


iLeg = 0;
for i = 1:N
    iVar = iDom(iDomStart(i):iDomStart(i+1)-1);
    p(iax,i) = plot(XaxisVar(iVar),YaxisVar(iVar));
    p(iax,i).Color = [color(i,:)];
    p(iax,i).Marker = markerType(i);
    p(iax,i).MarkerSize = 5;
    p(iax,i).LineWidth = 1.5;
    hold on

    iLeg = iLeg+1;
    legLabels(iLeg) = convertCharsToStrings( ...
        ['dp/dt|_{',varLegLabel,'} <= ',num2str(1e-3*dpdt_ub(i),3),' kPa/s']);
end

xlabel('volume (1000L) ', ...
'Interpreter','latex','FontSize',fontSize-1,'fontname','Times')
ylabel('power loss (x100\%)', ...
'Interpreter','latex','FontSize',fontSize-1,'fontname','Times')
switch par.ERUconfig.outlet
    case 1
        ERUstr = '';
    case 0
        ERUstr = 'and ERU Feed Outlet Downstream of Valve';
end
switch par.rvConfig.active
    case 0
        rvStr = 'Passive Ripple Control';
    case 1
        rvStr = 'Active Ripple Control';
end

titleString = ['Power Loss Normalized to Mean Power Capture With ',rvStr,ERUstr,':',newline,...
            varLabel,' Rate of Pressure Change Compared to Limit',newline,...
            'Sea State ',num2str(SS)];
title(titleString,...
'Interpreter','latex','FontSize',fontSize,'fontname','Times')

leg = legend(legLabels);
leg.FontSize = fontSize-1;
leg.FontName = 'Times';
rect = [0.5, -0.2, 0.25, 0.15];
% set(leg, 'Position', rect)
set(leg, 'Location', 'best')
xLim = xlim;
xlim([0 xLim(2)])
yLim = ylim;
ylim([0 yLim(2)])

% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% distribution of accumulators versus total volume
iax = 2;
ax(iax) = subplot(n_plots,1,iax);
ax(iax).FontName = 'times';
ax(iax).FontSize = fontSize-1;

for i = 1:N
    iVar = iDom(iDomStart(i):iDomStart(i+1)-1);
    p(iax,i) = plot(XaxisVar(iVar),100*X_mesh(iVar));
    p(iax,i).Color = [color(i,:)];
    p(iax,i).Marker = markerType(i);
    p(iax,i).MarkerSize = 5;
    p(iax,i).LineWidth = 1.5;
    hold on

end

xlabel('volume (1000L) ', ...
'Interpreter','latex','FontSize',fontSize-1,'fontname','Times')
ylabel('portion of volume at RO inlet (x100\%)', ...
'Interpreter','latex','FontSize',fontSize-1,'fontname','Times')
xLim = xlim;
xlim([0 xLim(2)])
yLim = ylim;
ylim([0 yLim(2)])

% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% distribution of accumulators versus total volume
iax = 3;
ax(iax) = subplot(n_plots,1,iax);
ax(iax).FontName = 'times';
ax(iax).FontSize = fontSize-1;

for i = 1:N
    iVar = iDom(iDomStart(i):iDomStart(i+1)-1);
    p(iax,i) = plot(XaxisVar(iVar),1000*sqrt(1e3)*kv_mesh(iVar));
    p(iax,i).Color = [color(i,:)];
    p(iax,i).Marker = markerType(i);
    p(iax,i).MarkerSize = 5;
    p(iax,i).LineWidth = 1.5;
    hold on

end

xlabel('volume (1000L) ', ...
'Interpreter','latex','FontSize',fontSize-1,'fontname','Times')
ylabel('valve coefficient (L/s/kPa^{1/2})', ...
'Interpreter','latex','FontSize',fontSize-1,'fontname','Times')
xLim = xlim;
xlim([0 xLim(2)])
yLim = ylim;
ylim([0 yLim(2)])

