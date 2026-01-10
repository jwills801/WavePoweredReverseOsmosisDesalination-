
f = linspace(-1,1,101);

for i = 1:numel(f)
    [f1(i),f2(i)] = fcn(f(i),0.5,0.5);
    F(i) = mean([f1(i),f2(i)]);
end

figure('Units','inches','Position',[1 1 4.5 4]) % Size the figure for a single column report
plot(f,f1,'LineWidth',2,'Color','b','DisplayName','pump a')
hold on
plot(f,f2,'LineWidth',2,'Color','r','DisplayName','pump b')
plot(f,F,'LineWidth',2,'Color','k','DisplayName','combined flow')
grid on
legend('show','Location','best')
xlabel('target total fractional displacement')
ylabel('resultant fractional displacement')
title({'Plot of Effective Fractional Displacement'; 'via Blended Pump Displacements'})
set(gca,'FontSize',10,'FontName','times')

function [f1,f2] = fcn(f,HIL_H1T_P1fBias,HIL_H1T_P2fBias)
    P1 = -HIL_H1T_P1fBias;
    P2 = HIL_H1T_P2fBias;
    
    f1 = (1/(1+P1))*(f-P1) * (f<=P1) ...
       + (2*P2/(P2-P1))*(f-P1) * ((P1 < f) & (f < P2)) ...
       + ((1-2*P2)/(1-P2)*f + 1 - (1-2*P2)/(1-P2)) * (f>=P2);
    
    f2 = ((1+2*P1)/(1+P1)*f + (1+2*P1)/(1+P1) - 1) * (f<=P1) ...
       + (2*P1/(P1-P2))*(f-P2) * ((P1 < f) & (f < P2)) ...
       + (1/(1-P2))*(f-P2) * (f>=P2);
end