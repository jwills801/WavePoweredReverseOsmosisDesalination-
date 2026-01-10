f = linspace(-1,1,1001);

for i = 1:numel(f)
    [duty(i), dutyMag(i)] = fcn(f(i),0.23,0.23);
end

figure
plot(f,duty.*dutyMag)
grid on


function [dutyMag,dutySign] = fcn(f,posCutIn, negCutIn)
duty = ((1-posCutIn)*f + posCutIn)*(f>0) + ...
    ((1-negCutIn)*f - negCutIn)*(f<0);
duty = max(-1,min(1,duty));
dutyMag = abs(duty);
dutySign = sign(duty);
end