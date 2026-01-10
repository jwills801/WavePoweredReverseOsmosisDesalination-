clear

duty = linspace(-1,1,101);

for i = 1:numel(duty)
    f(i) = fcn(duty(i));
end

figure
plot(duty,f)
grid on

function f  = fcn(duty)
posCutIn = 0.23;
negCutIn = 0.23;

f = ((duty-posCutIn)/(1-posCutIn))*(duty>posCutIn) + ...
    ((duty+negCutIn)/(1-negCutIn))*(duty<-negCutIn);
f = max(-1,min(1,f));
end